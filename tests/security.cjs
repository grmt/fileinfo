const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const source = fs.readFileSync(path.join(__dirname, '..', 'FileinfoApp.qml'), 'utf8');
const functions = source.match(/^\tfunction \w+\([^]*?^\t\}/gm).join('\n');
const defaults = JSON.parse(source.match(/property variant defaultRoadArray:\s*(\[[^]*?\])/)[1]);
const filterSource = fs.readFileSync(path.join(__dirname, '..', 'FileinfoFilterScreen.qml'), 'utf8');

function app() {
  const context = vm.createContext({
    fileinfoDataRead: true,
    fileinfoData: 'previous display',
    fileinfoDataAll: 'previous unfiltered data',
    fileinfoDataFiltered: 'previous filtered data',
    defaultRoadArray: defaults,
    fileinfoAvailableRoads: [...defaults],
    fileinfoFilterArray: 'A2,N',
    fileinfoFilterEnabled: false,
    fileinfoApiUrl: 'https://example.invalid/traffic',
    notifications: 0,
    requests: [],
    fileinfoSettingsFile: { read: () => '{}' },
  });
  context.fileinfoApp = context;
  context.fileinfoUpdated = () => context.notifications++;
  context.XMLHttpRequest = function () {
    context.requests.push(this);
    this.open = (method, url) => { this.method = method; this.url = url; };
    this.send = body => { this.body = body; };
  };
  for (let i = 1; i <= 5; i++) {
    Object.assign(context, {
      [`roadTile${i}Name`]: i === 1 ? 'A2' : '',
      [`roadTile${i}NumberOfJams`]: i === 1 ? 1 : 0,
      [`roadTile${i}TotalLength`]: i === 1 ? 2 : 0,
      [`roadTile${i}TotalDelay`]: i === 1 ? 60 : 0,
      [`roadTile${i}Roadworks`]: false,
      [`roadTile${i}`]: i === 1,
    });
  }
  vm.runInContext(functions, context);
  return context;
}

function response(jam = {}, road = 'A2') {
  return { roads: [{ road, segments: [{ start: 'Start', end: 'End', jams: [jam] }] }] };
}

function complete(context, body, status = 200) {
  context.updateFileinfoInfo();
  const request = context.requests.at(-1);
  Object.assign(request, { readyState: 4, status, responseText: body });
  request.onreadystatechange();
}

function snapshot(context) {
  return JSON.stringify(Object.fromEntries(Object.entries(context).filter(([key]) =>
    /^roadTile/.test(key) || ['fileinfoData', 'fileinfoDataAll',
      'fileinfoDataFiltered', 'fileinfoAvailableRoads'].includes(key))));
}

test('traffic XML preserves hostile text as one record and remains valid XML', () => {
  const context = app();
  const injected = '</description></melding><melding><description>forged';
  const markup = '<img src="https://example.invalid/image"> & \'quoted\'';
  const road = 'City & <District>';
  complete(context, JSON.stringify(response({ from: injected, to: injected, reason: markup }, road)));
  assert.equal(context.fileinfoDataRead, true);
  const parsed = spawnSync('python3', ['-c',
    'import sys,json,xml.etree.ElementTree as E; r=E.fromstring(sys.stdin.read()); '
      + 'print(json.dumps({"count":len(r),"road":r[0].findtext("wegnr"),'
      + '"description":r[0].findtext("description")}))'], { input: context.fileinfoData, encoding: 'utf8' });
  assert.equal(parsed.status, 0, parsed.stderr);
  assert.deepEqual(JSON.parse(parsed.stdout), {
    count: 1, road, description: `${injected}. ${markup}`,
  });
});

test('XML escaping removes forbidden controls and replaces unpaired surrogates', () => {
  const context = app();
  assert.equal(context.xmlText('\u0000\u0001\u000b\ufffe\uffffA\ud800B\udc00C😀'), 'A�B�C😀');
  assert.equal(context.xmlText('&<>"\''), '&amp;&lt;&gt;&quot;&apos;');
});

test('valid traffic supports city names, optional fields and both response envelopes', () => {
  const context = app();
  for (const payload of [response({}, 'Den Haag'), { data: response({}, 'Zoetermeer') }]) {
    const roads = context.parseRoads(JSON.stringify(payload));
    assert.equal(roads.length, 1);
    assert.equal(roads[0].segments[0].jams[0].distance, 0);
  }
  assert.equal(context.parseRoads('{"roads":[]}').length, 0);
  assert.equal(context.parseRoads('{"roads":[{"road":"A2"}]}')[0].segments.length, 0);
});

test('malformed responses preserve the previous display, tiles and filter options', () => {
  const invalid = [
    'not JSON', 'null', '[]', '{}', '{"roads":{}}',
    JSON.stringify({ roads: [null] }),
    JSON.stringify({ roads: [{ road: {} }] }),
    JSON.stringify({ roads: [{ road: 'A2', segments: {} }] }),
    JSON.stringify({ roads: [{ road: 'A2', segments: [null] }] }),
    JSON.stringify({ roads: [{ road: 'A2', segments: [{ jams: {} }] }] }),
    JSON.stringify(response(null)),
    JSON.stringify(response({ from: {} })),
    JSON.stringify(response({ reason: 'a'.repeat(4097) })),
    ...[-1, 'NaN', 'Infinity', {}, true, 2147483648].map(distance =>
      JSON.stringify(response({ distance }))),
    JSON.stringify({ roads: [{ road: 'A2', segments: [] }, null] }),
    JSON.stringify({ roads: Array(1025).fill({ road: 'A2' }) }),
    JSON.stringify({ roads: [{ road: 'A2', segments: Array(10001).fill({}) }] }),
    JSON.stringify(response()).replace('"jams":[{}]', '"jams":[' + Array(10001).fill('{}').join(',') + ']'),
    ' '.repeat(4 * 1024 * 1024 + 1),
  ];
  for (const body of invalid) {
    const context = app();
    const previous = snapshot(context);
    complete(context, body);
    assert.equal(context.fileinfoDataRead, false);
    assert.equal(context.notifications, 1);
    assert.equal(snapshot(context), previous);
  }
  const context = app();
  const previous = snapshot(context);
  complete(context, '{}', 503);
  assert.equal(context.fileinfoDataRead, false);
  assert.equal(context.notifications, 1);
  assert.equal(snapshot(context), previous);
});

test('valid updates retain filtering and separate jams from roadworks on the tile', () => {
  const context = app();
  context.fileinfoFilterEnabled = true;
  const payload = response({ from: 'A', to: 'B', distance: '2500', delay: '120' });
  payload.roads[0].segments[0].jams.push({ reason: 'Wegwerkzaamheden' });
  payload.roads.push(response({ reason: 'Other road' }, 'A1').roads[0]);
  complete(context, JSON.stringify(payload));
  assert.equal(context.fileinfoDataRead, true);
  assert.equal(context.notifications, 1);
  assert.equal(context.roadTile1Name, 'A2');
  assert.equal(context.roadTile1TotalLength, 2.5);
  assert.equal(context.roadTile1TotalDelay, 120);
  assert.equal(context.roadTile1Roadworks, false);
  assert.equal(context.roadTile2Name, 'A2');
  assert.equal(context.roadTile2Roadworks, true);
  assert.equal(context.roadTile3, false);
  assert.equal((context.fileinfoData.match(/<melding>/g) || []).length, 2);
  assert.equal((context.fileinfoDataAll.match(/<melding>/g) || []).length, 3);
});

function savedSettings(context) {
  return JSON.parse(context.requests.filter(request => request.method === 'PUT').at(-1).body);
}

function filterScreen(context) {
  const screen = vm.createContext({ app: context, currentPage: 0 });
  for (const suffix of ['A', 'N', 'Cities']) {
    const items = [];
    screen[`fileinfoFilterModel${suffix}`] = {
      clear: () => { items.length = 0; }, append: value => items.push(value), items,
      get count() { return items.length; }, get: index => items[index],
      setProperty: (index, key, value) => { items[index][key] = value; },
    };
    screen[`fileinfoFilterGroup${suffix}`] = {
      selected: [],
      clearSelectedControls() { this.selected = []; },
      setSelectedControls(indices) { this.selected = Array.from(indices); },
      getSelectedControls() { return this.selected; },
    };
    screen[`fileinfoFilterGridView${suffix}`] = { positionViewAtBeginning() {} };
  }
  Object.assign(screen, { pageTitle: {}, noCitiesText: {}, leftArrow: {}, rightArrow: {}, qsTr: text => text });
  vm.runInContext(filterSource.match(/^\tfunction \w+\([^]*?^\t\}/gm).join('\n'), screen);
  screen.show = () => vm.runInContext(filterSource.match(/\tonShown: \{([^]*?)^\t\}/m)[1], screen);
  screen.save = () => vm.runInContext(filterSource.match(/\tonSaved: \{([^]*?)^\t\}/m)[1], screen);
  return screen;
}

test('discovered roads and cities survive empty feeds and a restart without redundant writes', () => {
  const context = app();
  context.loadSettings();
  context.updateAvailableRoads([{ road: 'Zoetermeer' }, { road: 'Nijmegen' }, { road: 'N999' }]);
  const stored = savedSettings(context);
  const writes = context.requests.length;
  context.updateAvailableRoads([]);
  context.updateAvailableRoads([{ road: 'Zoetermeer' }]);
  assert.equal(context.requests.length, writes);
  for (const name of ['Zoetermeer', 'Nijmegen', 'N999', ...defaults]) {
    assert.ok(context.fileinfoAvailableRoads.includes(name), name);
    assert.ok(stored.knownRoads.includes(name), name);
  }
  const restarted = app();
  restarted.fileinfoSettingsFile.read = () => JSON.stringify(stored);
  restarted.loadSettings();
  restarted.updateAvailableRoads([]);
  assert.deepEqual(Array.from(restarted.fileinfoAvailableRoads), Array.from(context.fileinfoAvailableRoads));
  assert.equal(restarted.requests.length, 0);
});

test('legacy selections are migrated and survive opening and saving every filter page', () => {
  const context = app();
  context.fileinfoSettingsFile.read = () => JSON.stringify({
    roadFilter: 'A999,N999,Nijmegen,Den Haag,N', filterEnabled: 'Yes',
  });
  context.loadSettings();
  assert.equal(context.fileinfoFilterEnabled, true);
  assert.ok(savedSettings(context).knownRoads.includes('Nijmegen'));
  const screen = filterScreen(context);
  screen.show();
  assert.deepEqual(Array.from(screen.citiesArray), ['Den Haag', 'Nijmegen']);
  assert.ok(screen.aRoadsArray.includes('A999'));
  assert.ok(screen.nRoadsArray.includes('N999'));
  screen.currentPage = 2;
  screen.updatePageHeader();
  assert.equal(screen.pageTitle.text, 'Steden');
  assert.equal(screen.fileinfoFilterGridViewCities.visible, true);
  assert.equal(screen.rightArrow.enabled, false);
  screen.save();
  assert.deepEqual(context.fileinfoFilterArray.split(',').sort(), ['A999', 'Den Haag', 'N', 'N999', 'Nijmegen']);
  context.updateAvailableRoads([]);
  screen.show();
  assert.equal(screen.fileinfoFilterModelCities.items.filter(item => item.roadSelected).length, 2);
});

test('saving retains offscreen selections and clearing resets every model entry', () => {
  const context = app();
  context.fileinfoFilterArray = 'A325,N915,Zoetermeer';
  context.rememberRoads(Array.from({ length: 100 }, (_, i) => `Stad ${i}`));
  const screen = filterScreen(context);
  screen.show();
  // No delegates or ControlGroup selections are needed to retain these values.
  screen.save();
  assert.deepEqual(context.fileinfoFilterArray.split(',').sort(), ['A325', 'N915', 'Zoetermeer']);
  for (const suffix of ['A', 'N', 'Cities']) screen.clearRoadSelection(screen[`fileinfoFilterModel${suffix}`]);
  screen.save();
  assert.equal(context.fileinfoFilterArray, '');
});

test('individual N-roads, all N-roads and N-prefixed cities filter independently', () => {
  const payload = { roads: ['N3', 'N9', 'Nijmegen', 'Amsterdam'].map(name => response({}, name).roads[0]) };
  for (const [filter, expected] of [
    ['N3', ['N3']], ['N', ['N3', 'N9']], ['Nijmegen', ['Nijmegen']],
    ['N,Amsterdam', ['N3', 'N9', 'Amsterdam']],
  ]) {
    const context = app();
    context.fileinfoFilterEnabled = true;
    context.fileinfoFilterArray = filter;
    complete(context, JSON.stringify(payload));
    const names = Array.from(context.fileinfoData.matchAll(/<wegnr>(.*?)<\/wegnr>/g), match => match[1]);
    assert.deepEqual(names, expected);
    assert.equal(context.roadTile1Name, expected[0]);
  }
});

test('invalid saved catalogs are ignored and duplicate names do not accumulate', () => {
  for (const stored of ['null', 'not JSON', JSON.stringify({ knownRoads: {} }),
    JSON.stringify({ knownRoads: [null, {}, 123, '', 'N', 'Alle\nN-wegen', 'a'.repeat(4097), 'Den Haag', 'Den Haag'] })]) {
    const context = app();
    context.fileinfoSettingsFile.read = () => stored;
    context.loadSettings();
    assert.ok(context.fileinfoAvailableRoads.includes('A2'));
    assert.equal(new Set(context.fileinfoAvailableRoads).size, context.fileinfoAvailableRoads.length);
    assert.ok(context.fileinfoAvailableRoads.every(name => typeof name === 'string' && name.length <= 4096));
  }
});

test('live ANWB traffic response passes validation', {
  skip: !process.env.FILEINFO_LIVE_RESPONSE,
}, () => {
  const context = app();
  complete(context, fs.readFileSync(process.env.FILEINFO_LIVE_RESPONSE, 'utf8'));
  assert.equal(context.fileinfoDataRead, true);
  assert.equal(context.notifications, 1);
  assert.ok(context.fileinfoAvailableRoads.length > 1);
});
