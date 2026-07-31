pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Item {
    id: sportsService

    property bool enabled: Config.options.bar.sports.enable
    property string teamFilter: Config.options.bar.sports.teamFilter
    property int updateInterval: Config.options.bar.sports.updateInterval

    property var allGames: []
    property var customOrder: Config.options.bar.sports.customOrder
    onCustomOrderChanged: {
        if (JSON.stringify(Config.options.bar.sports.customOrder) !== JSON.stringify(customOrder)) {
            Config.options.bar.sports.customOrder = customOrder;
        }
    }
    property int currentGameIndex: 0
    property var currentGame: null
    onCurrentGameChanged: {
        if (currentGame) {
            Config.options.bar.sports.activeGameId = currentGame.id;
        } else {
            Config.options.bar.sports.activeGameId = "";
        }
    }

    property bool loading: false
    property string error: ""
    property var previousScores: ({})

    function nextGame() {
        if (allGames.length > 1) {
            currentGameIndex = (currentGameIndex + 1) % allGames.length;
            currentGame = allGames[currentGameIndex];
        }
    }

    function formatMatchTime(isoDate) {
        const date = new Date(isoDate);
        const format = Config.options.time.format;
        // format is "hh:mm", "h:mm ap", or "h:mm AP"
        // We want "ddd, at [Time]"
        let timePart = "";
        if (format.includes("ap") || format.includes("AP")) {
            // 12h
            timePart = Qt.formatDateTime(date, "h:mm ap");
        } else {
            // 24h
            timePart = Qt.formatDateTime(date, "hh:mm");
        }

        return Qt.formatDateTime(date, "ddd") + ", at " + timePart;
    }

    readonly property var leagueNames: ({
        "bra.1": "Brasileirão",
        "ger.1": "Bundesliga",
        "uefa.champions": "Champions League",
        "uefa.europa": "Europa League",
        "uefa.europa.conf": "Conference League",
        "conmebol.libertadores": "Libertadores",
        "eng.1": "Premier League",
        "esp.1": "LaLiga",
        "fra.1": "Ligue 1",
        "ita.1": "Serie A",
        "fifa.world": "World Cup",
        "fifa.wwc": "Women's World Cup"
    })

    function fetchGames() {
        if (!enabled) {
            allGames = [];
            return;
        }

        loading = true;
        error = "";

        let leaguesToFetch = [];
        let monitored = Config.options.bar.sports.monitoredLeagues;
        if (monitored && monitored.length > 0) {
            for (let i = 0; i < monitored.length; i++) {
                if (monitored[i].enabled) {
                    leaguesToFetch.push({
                        sport: monitored[i].sport,
                        league: monitored[i].league,
                        name: monitored[i].name
                    });
                }
            }
        } else {
            if (Config.options.bar.sports.showBRA) leaguesToFetch.push({ sport: "soccer", league: "bra.1", name: "Brasileirão" });
            if (Config.options.bar.sports.showBUND) leaguesToFetch.push({ sport: "soccer", league: "ger.1", name: "Bundesliga" });
            if (Config.options.bar.sports.showCL) leaguesToFetch.push({ sport: "soccer", league: "uefa.champions", name: "Champions League" });
            if (Config.options.bar.sports.showUEL) leaguesToFetch.push({ sport: "soccer", league: "uefa.europa", name: "Europa League" });
            if (Config.options.bar.sports.showUECL) leaguesToFetch.push({ sport: "soccer", league: "uefa.europa.conf", name: "Conference League" });
            if (Config.options.bar.sports.showCLA) leaguesToFetch.push({ sport: "soccer", league: "conmebol.libertadores", name: "Libertadores" });
            if (Config.options.bar.sports.showEPL) leaguesToFetch.push({ sport: "soccer", league: "eng.1", name: "Premier League" });
            if (Config.options.bar.sports.showLIGA) leaguesToFetch.push({ sport: "soccer", league: "esp.1", name: "LaLiga" });
            if (Config.options.bar.sports.showLIG1) leaguesToFetch.push({ sport: "soccer", league: "fra.1", name: "Ligue 1" });
            if (Config.options.bar.sports.showSERA) leaguesToFetch.push({ sport: "soccer", league: "ita.1", name: "Serie A" });
            if (Config.options.bar.sports.showWC) leaguesToFetch.push({ sport: "soccer", league: "fifa.world", name: "World Cup" });
            if (Config.options.bar.sports.showWWC) leaguesToFetch.push({ sport: "soccer", league: "fifa.wwc", name: "Women's World Cup" });
        }

        if (leaguesToFetch.length === 0) {
            allGames = [];
            loading = false;
            return;
        }

        function utcDateString(daysOffset) {
            const d = new Date();
            d.setUTCDate(d.getUTCDate() + daysOffset);
            return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}${String(d.getUTCDate()).padStart(2, '0')}`;
        }
        const daysNeeded = Math.ceil(Config.options.bar.sports.showBeforeHours / 24) + 1;
        let datesToFetch = [];
        for (let d = -1; d < daysNeeded; d++) datesToFetch.push(utcDateString(d));

        let requests = [];
        for (let i = 0; i < leaguesToFetch.length; i++) {
            const entry = leaguesToFetch[i];
            for (let j = 0; j < datesToFetch.length; j++) {
                requests.push({ entry: entry, date: datesToFetch[j] });
            }
        }

        let pendingRequests = requests.length;
        let collectedEvents = [];
        let seenEventIds = {};

        for (let i = 0; i < requests.length; i++) {
            const entry = requests[i].entry;
            const url = `https://site.api.espn.com/apis/site/v2/sports/${entry.sport}/${entry.league}/scoreboard?dates=${requests[i].date}`;
            const xhr = new XMLHttpRequest();
            xhr.open("GET", url);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    pendingRequests--;
                    if (xhr.status === 200) {
                        try {
                            const response = JSON.parse(xhr.responseText);
                            let leagueLogo = "";
                            if (response.leagues && response.leagues[0] && response.leagues[0].logos && response.leagues[0].logos[0]) {
                                leagueLogo = response.leagues[0].logos[0].href;
                            }
                            (response.events || []).forEach(e => {
                                if (!seenEventIds[e.id]) {
                                    seenEventIds[e.id] = true;
                                    e.leagueName = entry.name;
                                    e.sportCategory = entry.sport;
                                    e.leagueLogo = leagueLogo;
                                    collectedEvents.push(e);
                                }
                            });
                        } catch (e) {
                            error = "Parse error";
                        }
                    }
                    if (pendingRequests === 0) {
                        loading = false;
                        processGames(collectedEvents);
                    }
                }
            };
            xhr.send();
        }
    }

    function processGames(events) {
        let validGames = [];

        const filterStr = teamFilter.trim().toLowerCase();
        let teamsToMatch = [];
        if (filterStr !== "") {
            teamsToMatch = filterStr.split(',').map(t => t.trim()).filter(t => t.length > 0);
        }

        for (let i = 0; i < events.length; i++) {
            const event = events[i];
            if (!event.competitions || event.competitions.length === 0)
                continue;

            const eventDate = new Date(event.date);
            const now = new Date();
            const state = event.status.type.state;

            const hoursUntilStart = (eventDate - now) / (1000 * 60 * 60);
            if (state === "pre" && hoursUntilStart > Config.options.bar.sports.showBeforeHours)
                continue;

            const minsSinceStart = (now - eventDate) / (1000 * 60);
            if (state === "post" && minsSinceStart > Config.options.bar.sports.showAfterMinutes)
                continue;

            let comp = event.competitions[0];
            const isRacing = (event.sportCategory === "racing" || event.sportCategory === "motorsports" || event.leagueName.toLowerCase().includes("f1") || event.leagueName.toLowerCase().includes("formula"));

            if (isRacing && event.competitions.length > 1) {
                let activeComp = event.competitions.find(c => c.status.type.state === "in");
                if (activeComp) {
                    comp = activeComp;
                } else {
                    let preComp = event.competitions.find(c => c.status.type.state === "pre");
                    if (preComp) {
                        comp = preComp;
                    } else {
                        comp = event.competitions[event.competitions.length - 1];
                    }
                }
            }

            if (!comp.competitors) {
                comp.competitors = [];
            }

            let matchesFilter = false;
            if (teamsToMatch.length > 0) {
                if (isRacing) {
                    for (let k = 0; k < comp.competitors.length; k++) {
                        const competitor = comp.competitors[k];
                        const athleteName = competitor.athlete ? (competitor.athlete.displayName || "").toLowerCase() : "";
                        const teamName = competitor.team ? (competitor.team.displayName || competitor.team.name || "").toLowerCase() : "";
                        for (let j = 0; j < teamsToMatch.length; j++) {
                            const t = teamsToMatch[j];
                            if (athleteName.includes(t) || teamName.includes(t)) {
                                matchesFilter = true;
                                break;
                            }
                        }
                        if (matchesFilter) break;
                    }
                } else {
                    const homeNames = [
                        comp.competitors[0]?.team?.shortDisplayName,
                        comp.competitors[0]?.team?.displayName,
                        comp.competitors[0]?.team?.name
                    ].filter(Boolean).map(n => n.toLowerCase());
                    const awayNames = [
                        comp.competitors[1]?.team?.shortDisplayName,
                        comp.competitors[1]?.team?.displayName,
                        comp.competitors[1]?.team?.name
                    ].filter(Boolean).map(n => n.toLowerCase());
                    for (let j = 0; j < teamsToMatch.length; j++) {
                        const t = teamsToMatch[j];
                        if (homeNames.some(n => n === t) || awayNames.some(n => n === t)) {
                            matchesFilter = true;
                            break;
                        }
                    }
                }
            } else {
                matchesFilter = true;
            }

            if (matchesFilter) {
                let lastPlayText = "";
                const compState = comp.status ? comp.status.type.state : state;
                if (compState === "in") {
                    const situation = comp.situation || null;
                    lastPlayText = situation && situation.lastPlay && situation.lastPlay.text ? situation.lastPlay.text : "";

                    if (lastPlayText === "" && comp.details && comp.details.length > 0) {
                        const lastEvent = comp.details[comp.details.length - 1];
                        const type = lastEvent.type ? lastEvent.type.text : "";
                        const athlete = lastEvent.athletesInvolved && lastEvent.athletesInvolved.length > 0 ? lastEvent.athletesInvolved[0].displayName : "";
                        const clock = lastEvent.clock ? lastEvent.clock.displayValue : "";

                        if (type !== "") {
                            lastPlayText = `${type}${athlete !== "" ? " - " + athlete : ""}${clock !== "" ? " (" + clock + ")" : ""}`;
                        }
                    }
                }

                let home = { name: "TBD", score: "0", logo: event.leagueLogo || "", winner: false };
                let away = { name: "TBD", score: "0", logo: event.leagueLogo || "", winner: false };

                if (isRacing) {
                    if (comp.competitors.length > 0) {
                        const first = comp.competitors[0];
                        home = {
                            name: first.athlete ? (first.athlete.shortName || first.athlete.displayName) : (first.team ? first.team.shortDisplayName : "P1"),
                            score: first.displayValue || (first.score ? "P1 (" + first.score + ")" : "P1"),
                            logo: first.team ? first.team.logo : (first.athlete ? first.athlete.headshot : (event.leagueLogo || "")),
                            winner: first.winner || false
                        };
                    }
                    if (comp.competitors.length > 1) {
                        const second = comp.competitors[1];
                        away = {
                            name: second.athlete ? (second.athlete.shortName || second.athlete.displayName) : (second.team ? second.team.shortDisplayName : "P2"),
                            score: second.displayValue || (second.score ? "P2 (" + second.score + ")" : "P2"),
                            logo: second.team ? second.team.logo : (second.athlete ? second.athlete.headshot : (event.leagueLogo || "")),
                            winner: second.winner || false
                        };
                    }
                } else {
                    if (comp.competitors.length >= 2) {
                        let first = comp.competitors[0];
                        let second = comp.competitors[1];
                        if (first.homeAway === "away" || second.homeAway === "home") {
                            first = comp.competitors[1];
                            second = comp.competitors[0];
                        }
                        home = {
                            name: first.team ? (first.team.shortDisplayName || first.team.name) : "Home",
                            score: first.score || "0",
                            logo: first.team ? first.team.logo : "",
                            winner: first.winner || false
                        };
                        away = {
                            name: second.team ? (second.team.shortDisplayName || second.team.name) : "Away",
                            score: second.score || "0",
                            logo: second.team ? second.team.logo : "",
                            winner: second.winner || false
                        };
                    } else if (comp.competitors.length === 1) {
                        let first = comp.competitors[0];
                        home = {
                            name: first.team ? (first.team.shortDisplayName || first.team.name) : "Home",
                            score: first.score || "0",
                            logo: first.team ? first.team.logo : "",
                            winner: first.winner || false
                        };
                    }
                }

                if (!home.logo || home.logo === "") home.logo = event.leagueLogo || "";
                if (!away.logo || away.logo === "") away.logo = event.leagueLogo || "";

                validGames.push({
                    id: event.id,
                    name: event.name,
                    league: event.leagueName,
                    date: event.date,
                    status: (comp.status && comp.status.type && comp.status.type.state === "pre") ? formatMatchTime(event.date) : (comp.status ? comp.status.type.detail : (event.status ? event.status.type.detail : "")),
                    state: comp.status ? comp.status.type.state : state,
                    lastPlay: lastPlayText,
                    home: home,
                    away: away
                });
            }
        }

        function sortByStateAndDate(a, b) {
            const order = { "in": 0, "pre": 1, "post": 2 };
            const stateA = order[a.state] ?? 3;
            const stateB = order[b.state] ?? 3;
            if (stateA !== stateB) return stateA - stateB;
            const dateA = new Date(a.date);
            const dateB = new Date(b.date);
            return a.state === "post" ? dateB - dateA : dateA - dateB;
        }

        if (customOrder && customOrder.length > 0) {
            validGames.sort((a, b) => {
                let idxA = customOrder.indexOf(a.id);
                let idxB = customOrder.indexOf(b.id);
                if (idxA !== -1 && idxB !== -1) {
                    return idxA - idxB;
                }
                if (idxA !== -1) return -1;
                if (idxB !== -1) return 1;
                return sortByStateAndDate(a, b);
            });
        } else {
            validGames.sort(sortByStateAndDate);
        }

        let nextIndex = 0;
        let currentId = currentGame ? currentGame.id : Config.options.bar.sports.activeGameId;

        if (currentId) {
            let foundIndex = -1;
            for (let i = 0; i < validGames.length; i++) {
                if (validGames[i].id === currentId) {
                    foundIndex = i;
                    break;
                }
            }
            if (foundIndex !== -1) {
                nextIndex = foundIndex;
            } else if (currentGameIndex < validGames.length) {
                nextIndex = currentGameIndex;
            }
        } else if (currentGameIndex < validGames.length) {
            nextIndex = currentGameIndex;
        }

        for (let gi = 0; gi < validGames.length; gi++) {
            const game = validGames[gi];
            if (game.state !== "in") continue;
            const newHome = parseInt(game.home.score) || 0;
            const newAway = parseInt(game.away.score) || 0;
            const prev = previousScores[game.id];
            if (prev !== undefined && Config.options.bar.sports.goalNotifications) {
                const score = `${game.home.name} ${newHome} – ${newAway} ${game.away.name}`;
                const scorer = game.lastPlay ? `${game.lastPlay}\n` : "";
                if (newHome > prev.home) {
                    const homeIcon = `/tmp/qs_goal_${game.id}_home.png`;
                    Quickshell.execDetached(["bash", "-c",
                        `curl -fsSL "$1" -o "$4" 2>/dev/null; notify-send -i "$4" "$2" "$3" -a Shell`,
                        "--", game.home.logo, "⚽ Goal!", `${scorer}${score}`, homeIcon]);
                    Quickshell.execDetached(["mpv", "--no-video", "--really-quiet", `${Directories.assetsPath}/sounds/goal.mp3`]);
                }
                if (newAway > prev.away) {
                    const awayIcon = `/tmp/qs_goal_${game.id}_away.png`;
                    Quickshell.execDetached(["bash", "-c",
                        `curl -fsSL "$1" -o "$4" 2>/dev/null; notify-send -i "$4" "$2" "$3" -a Shell`,
                        "--", game.away.logo, "⚽ Goal!", `${scorer}${score}`, awayIcon]);
                    Quickshell.execDetached(["mpv", "--no-video", "--really-quiet", `${Directories.assetsPath}/sounds/goal.mp3`]);
                }
            }
            previousScores[game.id] = { home: newHome, away: newAway };
        }

        allGames = validGames;
        currentGameIndex = nextIndex;
        currentGame = allGames.length > 0 ? allGames[currentGameIndex] : null;
    }

    Timer {
        id: refreshTimer
        interval: updateInterval * 1000
        running: enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchGames()
    }

    onEnabledChanged: {
        if (enabled) {
            fetchGames();
        } else {
            allGames = [];
            currentGameIndex = 0;
            currentGame = null;
        }
    }

    onTeamFilterChanged: if (enabled)
        fetchGames()

    Connections {
        target: Config.options.bar.sports
        function onMonitoredLeaguesChanged() {
            if (enabled)
                fetchGames();
        }
    }
}
