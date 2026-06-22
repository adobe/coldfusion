const root = document.querySelector(".app-shell");
const debugMode = root?.dataset.debug === "1";

const els = {
  scenarioScreen: document.getElementById("scenarioScreen"),
  scenarioGrid: document.getElementById("scenarioGrid"),
  scenarioEmpty: document.getElementById("scenarioEmpty"),
  refreshScenarios: document.getElementById("refreshScenarios"),
  selectedTitle: document.getElementById("selectedTitle"),
  selectedImage: document.getElementById("selectedImage"),
  selectedSubtitle: document.getElementById("selectedSubtitle"),
  selectedIntro: document.getElementById("selectedIntro"),
  selectedMeta: document.getElementById("selectedMeta"),
  startMystery: document.getElementById("startMystery"),
  gameScreen: document.getElementById("gameScreen"),
  roomImage: document.getElementById("roomImage"),
  caseTitle: document.getElementById("caseTitle"),
  roomName: document.getElementById("roomName"),
  roomDescription: document.getElementById("roomDescription"),
  narrativeLog: document.getElementById("narrativeLog"),
  quickActions: document.getElementById("quickActions"),
  commandForm: document.getElementById("commandForm"),
  commandInput: document.getElementById("commandInput"),
  exitList: document.getElementById("exitList"),
  objectList: document.getElementById("objectList"),
  inventoryList: document.getElementById("inventoryList"),
  clueProgress: document.getElementById("clueProgress"),
  clueList: document.getElementById("clueList"),
  suspectList: document.getElementById("suspectList"),
  solvedModal: document.getElementById("solvedModal"),
  solvedTitle: document.getElementById("solvedTitle"),
  solvedText: document.getElementById("solvedText"),
  returnToCases: document.getElementById("returnToCases")
};

let currentState = null;
let scenarios = [];
let selectedScenario = null;
let roomTransitionId = 0;
let solvedModalShown = false;

async function api(path, options = {}) {
  const suffix = debugMode ? `${path.includes("?") ? "&" : "?"}debug=1` : "";
  const response = await fetch(`${path}${suffix}`, {
    headers: {"Content-Type": "application/json"},
    credentials: "same-origin",
    ...options
  });
  return response.json();
}

function text(value) {
  return value == null ? "" : String(value);
}

function displayLabel(value) {
  return text(value).replace(/_/g, " ");
}

function addLog(message, type = "system") {
  const entry = document.createElement("p");
  entry.className = `log-entry ${type}`;
  entry.textContent = message;
  els.narrativeLog.appendChild(entry);
  els.narrativeLog.scrollTop = els.narrativeLog.scrollHeight;
}

function clear(node) {
  while (node.firstChild) node.removeChild(node.firstChild);
}

function chip(label, command, title = "", extraClass = "", disabled = false) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = `chip${extraClass ? ` ${extraClass}` : ""}`;
  button.textContent = label;
  if (title) button.title = title;
  button.disabled = Boolean(disabled);
  if (!disabled) {
    button.addEventListener("click", () => submitCommand(command));
  }
  return button;
}

async function loadScenarios() {
  clear(els.scenarioGrid);
  clear(els.selectedMeta);
  els.scenarioEmpty.hidden = true;
  selectedScenario = null;
  scenarios = [];
  updateSelectedScenario(null);

  try {
    const data = await api("api/scenarios.cfm");
    if (!data.success) throw new Error(data.message || "Scenario scan failed.");

    scenarios = data.scenarios;

    if (!data.scenarios.length) {
      els.scenarioEmpty.hidden = false;
      return;
    }

    data.scenarios.forEach((scenario) => {
      const card = document.createElement("button");
      card.type = "button";
      card.className = "case-card";
      const image = document.createElement("img");
      image.className = "case-card-image";
      image.src = scenario.thumbnail || "";
      image.alt = "";
      const content = document.createElement("span");
      content.className = "case-card-content";
      const genre = document.createElement("span");
      genre.className = "eyebrow";
      genre.textContent = displayLabel(scenario.genre || "Mystery");
      const title = document.createElement("h2");
      title.textContent = scenario.title;
      const subtitle = document.createElement("p");
      subtitle.textContent = scenario.subtitle || "";
      const meta = document.createElement("span");
      meta.className = "case-meta";
      [scenario.tone || "Atmospheric"].forEach((value) => {
        const tag = document.createElement("span");
        tag.className = "tag";
        tag.textContent = displayLabel(value);
        meta.appendChild(tag);
      });
      content.append(genre, title, subtitle, meta);
      card.append(image, content);
      card.addEventListener("click", () => selectScenario(scenario.file));
      els.scenarioGrid.appendChild(card);
    });

    selectScenario(data.scenarios[0].file);
  } catch (error) {
    els.scenarioEmpty.hidden = false;
    els.scenarioEmpty.textContent = error.message;
  }
}

function selectScenario(file) {
  selectedScenario = scenarios.find((scenario) => scenario.file === file) || null;
  updateSelectedScenario(selectedScenario);

  Array.from(els.scenarioGrid.querySelectorAll(".case-card")).forEach((card, index) => {
    const scenario = scenarios[index];
    card.classList.toggle("is-selected", Boolean(scenario && selectedScenario && scenario.file === selectedScenario.file));
  });
}

function updateSelectedScenario(scenario) {
  els.startMystery.disabled = !scenario;
  els.selectedTitle.textContent = scenario ? scenario.title : "Choose a case";
  els.selectedSubtitle.textContent = scenario ? (scenario.subtitle || "No public case summary supplied.") : "Select a mystery file, then start the investigation.";
  els.selectedIntro.textContent = scenario ? (scenario.intro || "") : "";
  els.selectedImage.hidden = !scenario;
  els.selectedImage.src = scenario ? (scenario.thumbnail || "") : "";
  els.selectedImage.alt = scenario ? `${scenario.title} starting room` : "";
  clear(els.selectedMeta);

  if (!scenario) return;

  [
    ["Genre", scenario.genre || "Mystery"],
    ["Tone", scenario.tone || "Unspecified"],
    ["Start", scenario.startingRoom || "Unknown"]
  ].forEach(([label, value]) => {
    const term = document.createElement("dt");
    term.textContent = label;
    const detail = document.createElement("dd");
    detail.textContent = value;
    els.selectedMeta.append(term, detail);
  });
}

async function startScenario(file) {
  const data = await api("api/start.cfm", {
    method: "POST",
    body: JSON.stringify({file})
  });

  if (!data.success) {
    addLog(data.message || data.error || "Unable to start case.", "system");
    return;
  }

  els.scenarioScreen.hidden = true;
  els.gameScreen.hidden = false;
  hideSolvedModal();
  solvedModalShown = false;
  currentState = data.state;
  renderState(currentState);
  clear(els.narrativeLog);
  addLog(data.intro || data.message || "Case loaded.", "system");
  els.commandInput.focus();
}

async function submitCommand(command) {
  const value = text(command || els.commandInput.value).trim();
  if (!value) return;

  addLog(`> ${value}`, "command");
  els.commandInput.value = "";

  try {
    const data = await api("api/action.cfm", {
      method: "POST",
      body: JSON.stringify({command: value})
    });

    if (data.state) {
      currentState = data.state;
      renderState(currentState, data.stateChanges || {});
    }

    addLog(data.narration || data.message || "The house gives no answer.", data.success ? "system" : "system");

    if (currentState?.solved) {
      showSolvedModal();
    }
  } catch (error) {
    addLog(error.message || "The house system faulted.", "system");
  }
}

function renderState(state, changes = {}) {
  renderRoom(state.currentRoom);
  renderQuickActions(state);
  const visitedRoomIds = new Set((state.visitedRooms || []).map((id) => text(id).toLowerCase()));
  renderChips(els.exitList, state.currentRoom.exits, (room) => {
    const visited = visitedRoomIds.has(text(room.id).toLowerCase());
    return chip(
      room.name,
      `go to ${room.name}`,
      visited ? "Already visited" : "",
      visited ? "is-visited" : ""
    );
  });
  renderChips(els.objectList, state.currentRoom.visibleObjects, (item) => {
    const classes = [
      item.examined ? "is-examined" : "",
      item.portable ? "is-portable" : ""
    ].filter(Boolean).join(" ");
    const hints = [
      item.examined ? "Already examined" : "",
      item.portable ? "Carryable" : "",
      item.description || ""
    ].filter(Boolean).join(" - ");
    return chip(item.name, `examine ${item.name}`, hints, classes);
  });
  renderInventory(state.inventory);
  renderClueProgress(state);
  renderClues(state.discoveredClues);
  renderSuspects(state.suspects);

  if ((changes.revealedClues && changes.revealedClues.length) || (changes.revealedObjects && changes.revealedObjects.length)) {
    els.clueList.closest(".panel").classList.remove("toast-glow");
    window.requestAnimationFrame(() => els.clueList.closest(".panel").classList.add("toast-glow"));
  }
}

function renderRoom(room) {
  const currentSrc = els.roomImage.getAttribute("src");
  if (!currentSrc) {
    setRoomContent(room);
    return;
  }

  if (currentSrc === room.image) {
    setRoomContent(room);
    return;
  }

  transitionRoom(room);
}

function setRoomContent(room) {
  els.roomImage.src = room.image;
  els.roomImage.alt = room.name;
  els.caseTitle.textContent = currentState.title;
  els.roomName.textContent = room.name;
  els.roomDescription.textContent = room.description;
}

function transitionRoom(room) {
  const transitionId = ++roomTransitionId;
  els.roomImage.classList.remove("room-transition-in", "room-transition-out");
  void els.roomImage.offsetWidth;
  els.roomImage.classList.add("room-transition-out");

  window.setTimeout(() => {
    if (transitionId !== roomTransitionId) return;

    setRoomContent(room);
    els.roomImage.classList.remove("room-transition-out");
    void els.roomImage.offsetWidth;
    els.roomImage.classList.add("room-transition-in");

    window.setTimeout(() => {
      if (transitionId === roomTransitionId) {
        els.roomImage.classList.remove("room-transition-in");
      }
    }, 780);
  }, 620);
}

function renderQuickActions(state) {
  clear(els.quickActions);
  [
    ["Look", "look around"],
    ["Search", "search room"],
    ["Inventory", "inventory"],
    ["Clues", "clues"],
    ["Ask IRIS", "ask iris what seems suspicious here?"]
  ].forEach(([label, command]) => els.quickActions.appendChild(chip(label, command)));

  const criticalProgress = state.criticalPathProgress || {};
  const criticalFound = Number(criticalProgress.found || 0);
  const criticalTotal = Number(criticalProgress.total || 0);
  const criticalRemaining = Math.max(0, criticalProgress.remaining == null ? criticalTotal - criticalFound : Number(criticalProgress.remaining));
  const hintDisabled = criticalTotal === 0 || criticalRemaining === 0;
  const hintTitle = criticalTotal === 0
    ? "No critical evidence thread is configured for this case."
    : criticalRemaining === 0
      ? "The core evidence thread is complete."
      : "Ask IRIS for a spoiler-light nudge toward the next core clue.";
  els.quickActions.appendChild(chip("Give me a hint", "hint", hintTitle, "hint-chip", hintDisabled));
  els.quickActions.appendChild(chip("Help", "help"));

  if (state.suspects.length) {
    const progress = state.clueProgress || {};
    const found = Number(progress.found || 0);
    const total = Number(progress.total || 0);
    const remaining = progress.remaining == null ? Math.max(0, total - found) : Number(progress.remaining);
    const readyToAccuse = total > 0 && remaining === 0;
    const accuse = chip(
      "Accuse",
      "accuse",
      readyToAccuse ? "All clues are found. Name your suspect." : "Name a suspect when you are ready."
    );
    accuse.classList.toggle("accuse-ready", readyToAccuse);
    els.quickActions.appendChild(accuse);
  }
}

function renderChips(node, rows, factory) {
  clear(node);
  if (!rows.length) {
    const empty = document.createElement("span");
    empty.className = "tag";
    empty.textContent = "None";
    node.appendChild(empty);
    return;
  }
  rows.forEach((row) => node.appendChild(factory(row)));
}

function renderInventory(rows) {
  clear(els.inventoryList);
  if (!rows.length) {
    const empty = document.createElement("p");
    empty.className = "item";
    empty.textContent = "Nothing carried.";
    els.inventoryList.appendChild(empty);
    return;
  }

  rows.forEach((row) => {
    const item = document.createElement("button");
    item.type = "button";
    item.className = `item inventory-item${row.examined ? " is-examined" : ""}`;
    item.title = row.examined ? "Already examined" : "Examine this item";
    item.addEventListener("click", () => submitCommand(`examine ${row.name}`));

    const name = document.createElement("strong");
    name.textContent = row.name;
    const description = document.createElement("span");
    description.textContent = row.description || "";
    item.append(name, description);
    els.inventoryList.appendChild(item);
  });
}

function renderClueProgress(state) {
  const progress = state.clueProgress || {
    found: (state.discoveredClues || []).length,
    total: (state.discoveredClues || []).length,
    remaining: 0
  };
  const found = Number(progress.found || 0);
  const total = Number(progress.total || 0);
  const remaining = Math.max(0, progress.remaining == null ? total - found : Number(progress.remaining));
  els.clueProgress.textContent = `${found} / ${total} found - ${remaining} left`;
  els.clueProgress.title = remaining ? `${remaining} clues still hidden` : "All clues found";
  els.clueProgress.classList.toggle("is-complete", total > 0 && remaining === 0);
}

function renderClues(rows) {
  clear(els.clueList);
  if (!rows.length) {
    const empty = document.createElement("p");
    empty.className = "item";
    empty.textContent = "No confirmed clues.";
    els.clueList.appendChild(empty);
    return;
  }

  rows.forEach((clue) => {
    const item = document.createElement("div");
    item.className = "item";
    const title = document.createElement("strong");
    title.textContent = clue.title;
    const body = document.createElement("p");
    body.textContent = clue.text || "";
    item.append(title, body);
    els.clueList.appendChild(item);
  });
}

function renderSuspects(rows) {
  clear(els.suspectList);
  rows.forEach((suspect) => {
    const item = document.createElement("div");
    item.className = "item";
    const name = document.createElement("strong");
    name.textContent = suspect.name;
    const role = document.createElement("span");
    role.textContent = suspect.role;
    const description = document.createElement("p");
    description.textContent = suspect.publicDescription || "";
    item.append(name, role, description);
    els.suspectList.appendChild(item);
  });
}

function showSolvedModal() {
  if (solvedModalShown || !els.solvedModal) return;

  solvedModalShown = true;
  els.solvedTitle.textContent = "You've solved the case!";
  els.solvedText.textContent = `You won the investigation${currentState?.title ? `: ${currentState.title}` : ""}. IRIS has enough evidence to close the file.`;
  els.solvedModal.hidden = false;
  els.returnToCases.focus();
}

function hideSolvedModal() {
  if (els.solvedModal) {
    els.solvedModal.hidden = true;
  }
}

async function returnToScenarioSelection() {
  try {
    await api("api/reset.cfm", {method: "POST"});
  } catch (error) {
    addLog(error.message || "Unable to reset the case state.", "system");
  }

  hideSolvedModal();
  solvedModalShown = false;
  currentState = null;
  roomTransitionId = 0;
  els.gameScreen.hidden = true;
  els.scenarioScreen.hidden = false;
  clear(els.narrativeLog);
  await loadScenarios();
  els.startMystery.focus();
}

els.commandForm.addEventListener("submit", (event) => {
  event.preventDefault();
  submitCommand();
});

els.refreshScenarios.addEventListener("click", loadScenarios);
els.startMystery.addEventListener("click", () => {
  if (selectedScenario) {
    startScenario(selectedScenario.file);
  }
});
els.returnToCases.addEventListener("click", returnToScenarioSelection);

loadScenarios();
