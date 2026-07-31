pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell

/**
 * - Eases fuzzy searching for applications by name
 * - Guesses icon name for window class name
 */
Singleton {
    id: root
    property bool sloppySearch: Config.options?.search.sloppy ?? false
    property bool frecencySearch: Config.options?.search.frecency ?? false
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "zen": "zen-browser",
        "brave-browser": "brave-desktop",
        "net.lutris.lutris": "net.lutris.Lutris",
        "org.gnome.texteditor": "org.gnome.TextEditor",
        "org.kde.kdeconnect.app": "kdeconnect",
        "opentabletdriver.ux": "otd",
        "chrome-chat.openai.com__-default": Config.options?.appearance.icons.enableThemed
            ? "vynx-dock-chatgpt" : Quickshell.shellPath("assets/dock/ChatGPT.svg"),
        "chrome-gemini.google.com__app-default": Config.options?.appearance.icons.enableThemed
            ? "vynx-dock-gemini" : Quickshell.shellPath("assets/dock/gemini.svg"),
        "chrome-translate.google.com__-default": "google-translate",
        "kitty-yazi": "yazi",
        "kitty-btop": "btop"
    })
    property var regexSubstitutions: [
        {
            "regex": /^steam_app_(\d+)$/,
            "replace": "steam_icon_$1"
        },
        {
            "regex": /Minecraft.*/,
            "replace": "minecraft"
        },
        {
            "regex": /.*polkit.*/,
            "replace": "system-lock-screen"
        },
        {
            "regex": /gcr.prompter/,
            "replace": "system-lock-screen"
        }
    ]
    // Maps window title regex → stable appId, for apps with empty class
    property var titleAppIdSubstitutions: [
        { "regex": /^RPCS3/, "appId": "rpcs3" }
    ]

    function getAppIdFromTitle(title) {
        if (!title) return "";
        for (let i = 0; i < titleAppIdSubstitutions.length; i++) {
            if (titleAppIdSubstitutions[i].regex.test(title))
                return titleAppIdSubstitutions[i].appId;
        }
        return "";
    }

    // Deduped list to fix double icons, pre-sorted alphabetically to avoid sorting on every query
    readonly property list<DesktopEntry> list: {
        var arr = Array.from(DesktopEntries.applications.values).filter((app, index, self) => index === self.findIndex(t => (t.id === app.id)));
        arr.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return arr;
    }

    readonly property var preppedNames: list.map(a => ({
        name: Fuzzy.prepare(`${a.name} `),
        entry: a
    }))

    readonly property var preppedIcons: list.map(a => ({
        name: Fuzzy.prepare(`${a.icon} `),
        entry: a
    }))

    function frecencyQuery(search: string): var {
        if (search === "") {
            const scored = list.map(obj => ({
                        entry: obj,
                        score: AppUsage.getScore(obj.id)
                    }));
            // Split: apps with score > 0 sorted by score desc, then rest alphabetically (since list is already sorted, filter preserves order)
            const used = scored.filter(item => item.score > 0).sort((a, b) => b.score - a.score);
            const unused = scored.filter(item => item.score === 0);
            return used.concat(unused).map(item => item.entry);
        }

        const fuzzyResults = Fuzzy.go(search, preppedNames, { all: false, key: "name" });
        if (fuzzyResults.length === 0) return [];

        let maxFuzzy = 0;
        for (let i = 0; i < fuzzyResults.length; i++) {
            if (fuzzyResults[i].score > maxFuzzy) maxFuzzy = fuzzyResults[i].score;
        }

        const results = fuzzyResults.map(r => {
            const entry = r.obj.entry;
            const normalizedFuzzy = maxFuzzy > 0 ? r.score / maxFuzzy : 1;
            const usageScore = AppUsage.getScore(entry.id);
            const normalizedUsage = usageScore > 0 ? Math.min(1, Math.log(usageScore + 1) / Math.log(100)) : 0;
            const prefixBonus = entry.name.toLowerCase().startsWith(search.toLowerCase()) ? 1.0 : 0.0;
            return { entry: entry, combinedScore: normalizedFuzzy * 0.6 + normalizedUsage * 0.4 + prefixBonus };
        });

        return results.sort((a, b) => b.combinedScore - a.combinedScore).map(item => item.entry);
    }

    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        if (search === "") {
            if (root.frecencySearch) {
                return frecencyQuery(search);
            }
            return list;
        }

        if (root.frecencySearch) return frecencyQuery(search);

        if (root.sloppySearch) {
            const results = list.map(obj => ({
                entry: obj,
                score: Levendist.computeScore(obj.name.toLowerCase(), search.toLowerCase())
            })).filter(item => item.score > root.scoreThreshold)
                .sort((a, b) => b.score - a.score)
            return results
                .map(item => item.entry)
        }

        return Fuzzy.go(search, preppedNames, {
            limit: 100,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
    }

    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }

    function getReverseDomainNameAppName(str) {
        return str.split('.').slice(-1)[0]
    }

    function getKebabNormalizedAppName(str) {
        return str.toLowerCase().replace(/\s+/g, "-");
    }

    function getUndescoreToKebabAppName(str) {
        return str.toLowerCase().replace(/_/g, "-");
    }

    function guessIcon(str, title = "") {
        if (!str || str.length == 0) {
            if (title && title.length > 0) {
                const syntheticId = getAppIdFromTitle(title);
                if (syntheticId) return guessIcon(syntheticId);
            }
            return "image-missing";
        }

        // Quickshell's desktop entry lookup
        const entry = DesktopEntries.byId(str);
        if (entry) return entry.icon;

        // Normal substitutions
        if (substitutions[str]) return substitutions[str];
        if (substitutions[str.toLowerCase()]) return substitutions[str.toLowerCase()];

        // Regex substitutions
        for (let i = 0; i < regexSubstitutions.length; i++) {
            const substitution = regexSubstitutions[i];
            const replacedName = str.replace(
                substitution.regex,
                substitution.replace,
            );
            if (replacedName != str) return replacedName;
        }

        // Icon exists -> return as is
        if (iconExists(str)) return str;


        // Simple guesses
        const lowercased = str.toLowerCase();
        if (iconExists(lowercased)) return lowercased;

        const reverseDomainNameAppName = getReverseDomainNameAppName(str);
        if (iconExists(reverseDomainNameAppName)) return reverseDomainNameAppName;

        const lowercasedDomainNameAppName = reverseDomainNameAppName.toLowerCase();
        if (iconExists(lowercasedDomainNameAppName)) return lowercasedDomainNameAppName;

        const kebabNormalizedGuess = getKebabNormalizedAppName(str);
        if (iconExists(kebabNormalizedGuess)) return kebabNormalizedGuess;

        const undescoreToKebabGuess = getUndescoreToKebabAppName(str);
        if (iconExists(undescoreToKebabGuess)) return undescoreToKebabGuess;

        // Search in desktop entries
        const iconSearchResults = Fuzzy.go(str, preppedIcons, {
            limit: 10,
            key: "name"
        }).map(r => {
            return r.obj.entry
        });
        if (iconSearchResults.length > 0) {
            const guess = iconSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        const nameSearchResults = root.fuzzyQuery(str);
        if (nameSearchResults.length > 0) {
            const guess = nameSearchResults[0].icon
            if (iconExists(guess)) return guess;
        }

        // Quickshell's desktop entry lookup
        const heuristicEntry = DesktopEntries.heuristicLookup(str);
        if (heuristicEntry) return heuristicEntry.icon;

        // Give up
        return "application-x-executable";
    }
}
