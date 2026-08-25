const AXES = [
    { key: 'x', label: 'Pos X', kind: 'pos' },
    { key: 'y', label: 'Pos Y', kind: 'pos' },
    { key: 'z', label: 'Pos Z', kind: 'pos' },
    { key: 'rx', label: 'Rot X', kind: 'rot' },
    { key: 'ry', label: 'Rot Y', kind: 'rot' },
    { key: 'rz', label: 'Rot Z', kind: 'rot' },
];

const state = {
    open: false,
    attach: null,
    steps: {
        fine: { pos: 0.001, rot: 0.1 },
        normal: { pos: 0.01, rot: 1 },
        coarse: { pos: 0.05, rot: 5 },
    },
    step: 'normal',
    heldStep: null,
    maxOffset: 0.85,
};

const inGame = typeof window.GetParentResourceName === 'function';
const resourceName = inGame ? window.GetParentResourceName() : 'djfivem-wings';
const PREVIEW_DEFAULT = {
    id: 'neon_pink_wings',
    slot: 'wings',
    bone: 24818,
    x: 0,
    y: -0.18,
    z: 0.02,
    rx: 0,
    ry: 90,
    rz: 180,
};

function nui(name, payload) {
    if (!inGame) {
        if (name === 'reset') {
            return Promise.resolve({ ok: true, attach: { ...PREVIEW_DEFAULT } });
        }
        return Promise.resolve({ ok: true, attach: state.attach });
    }
    return fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload || {}),
    }).then((res) => res.json()).catch(() => ({ ok: false }));
}

function clamp(n, min, max) {
    return Math.min(max, Math.max(min, n));
}

function round(n, kind) {
    const digits = kind === 'pos' ? 3 : 2;
    return Number(Number(n).toFixed(digits));
}

function currentStep(kind) {
    const name = state.heldStep || state.step;
    return state.steps[name][kind];
}

function luaSnippet() {
    const a = state.attach;
    return [
        'default = {',
        `    x = ${a.x.toFixed(3)},`,
        `    y = ${a.y.toFixed(3)},`,
        `    z = ${a.z.toFixed(3)},`,
        `    rx = ${a.rx.toFixed(2)},`,
        `    ry = ${a.ry.toFixed(2)},`,
        `    rz = ${a.rz.toFixed(2)},`,
        '},',
        `-- bone = ${a.bone}`,
    ].join('\n');
}

function toast(text) {
    const old = document.querySelector('.toast');
    if (old) old.remove();
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = text;
    const panel = document.querySelector('.panel');
    panel.insertBefore(el, panel.firstChild);
    setTimeout(() => el.remove(), 2200);
}

function applyAttach(next) {
    const max = state.maxOffset;
    state.attach = {
        id: next.id,
        slot: next.slot,
        bone: Number(next.bone),
        x: round(clamp(Number(next.x) || 0, -max, max), 'pos'),
        y: round(clamp(Number(next.y) || 0, -max, max), 'pos'),
        z: round(clamp(Number(next.z) || 0, -max, max), 'pos'),
        rx: round((Number(next.rx) || 0) % 360, 'rot'),
        ry: round((Number(next.ry) || 0) % 360, 'rot'),
        rz: round((Number(next.rz) || 0) % 360, 'rot'),
    };
    AXES.forEach(({ key }) => {
        const input = document.getElementById(key);
        if (input) input.value = state.attach[key];
    });
    const bone = document.getElementById('bone');
    if (bone) bone.value = String(state.attach.bone);
}

function preview() {
    nui('preview', state.attach).then((res) => {
        if (res && res.attach) applyAttach(res.attach);
    });
}

function nudge(key, kind, dir) {
    if (!state.attach) return;
    const next = { ...state.attach };
    next[key] = next[key] + currentStep(kind) * dir;
    applyAttach(next);
    preview();
}

function renderAxes() {
    const root = document.getElementById('axes');
    root.innerHTML = '';
    AXES.forEach((axis) => {
        const row = document.createElement('div');
        row.className = 'axis';
        row.innerHTML = `
            <span>${axis.label}</span>
            <button type="button" data-axis="${axis.key}" data-dir="-1">−</button>
            <input id="${axis.key}" type="number" step="0.001" />
            <button type="button" data-axis="${axis.key}" data-dir="1">+</button>
        `;
        root.appendChild(row);
        row.querySelectorAll('button').forEach((btn) => {
            btn.addEventListener('click', () => nudge(axis.key, axis.kind, Number(btn.dataset.dir)));
        });
        row.querySelector('input').addEventListener('change', (event) => {
            const next = { ...state.attach, [axis.key]: event.target.value };
            applyAttach(next);
            preview();
        });
    });
}

function fillBones(bones) {
    const select = document.getElementById('bone');
    select.innerHTML = '';
    (bones || []).forEach((bone) => {
        const opt = document.createElement('option');
        opt.value = String(bone.id);
        opt.textContent = `${bone.name} (${bone.id})`;
        select.appendChild(opt);
    });
}

function openEditor(data) {
    state.open = true;
    state.steps = data.steps || state.steps;
    state.maxOffset = data.maxOffset || 0.85;
    document.getElementById('propLabel').textContent = data.label || 'Wearable';
    document.getElementById('slotBadge').textContent = data.slot || 'slot';
    fillBones(data.bones || []);
    applyAttach(data.attach);
    document.getElementById('app').classList.remove('hidden');
}

function closeEditor() {
    state.open = false;
    document.getElementById('app').classList.add('hidden');
}

document.querySelectorAll('[data-step]').forEach((btn) => {
    btn.addEventListener('click', () => {
        state.step = btn.dataset.step;
        document.querySelectorAll('[data-step]').forEach((el) => el.classList.toggle('active', el === btn));
    });
});

document.getElementById('bone').addEventListener('change', (event) => {
    applyAttach({ ...state.attach, bone: event.target.value });
    preview();
});

document.getElementById('btnSave').addEventListener('click', () => nui('save', state.attach));
document.getElementById('btnReset').addEventListener('click', () => {
    nui('reset').then((res) => {
        if (res && res.attach) applyAttach(res.attach);
    });
});
document.getElementById('btnCancel').addEventListener('click', () => nui('cancel'));
document.getElementById('btnCopy').addEventListener('click', async () => {
    const text = luaSnippet();
    let copied = false;
    try {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            await navigator.clipboard.writeText(text);
            copied = true;
        }
    } catch (err) {
        copied = false;
    }
    if (!copied) {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.style.position = 'fixed';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        try {
            copied = document.execCommand('copy');
        } catch (err) {
            copied = false;
        }
        ta.remove();
    }
    toast(copied ? 'Copied default table' : 'Lua snippet ready');
});

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') openEditor(msg.data || {});
    if (msg.action === 'close') closeEditor();
});

window.addEventListener('keydown', (event) => {
    if (!state.open) return;

    if (['INPUT', 'SELECT', 'TEXTAREA'].includes(event.target.tagName) && !event.altKey) {
        if (event.key === 'Escape') {
            event.preventDefault();
            nui('cancel');
        }
        return;
    }

    if (event.key === 'Shift') state.heldStep = 'fine';
    if (event.key === 'Control') state.heldStep = 'coarse';

    const map = {
        Numpad4: ['x', 'pos', -1],
        Numpad6: ['x', 'pos', 1],
        Numpad8: ['y', 'pos', 1],
        Numpad5: ['y', 'pos', -1],
        Numpad7: ['z', 'pos', 1],
        Numpad9: ['z', 'pos', -1],
        ArrowLeft: ['rz', 'rot', -1],
        ArrowRight: ['rz', 'rot', 1],
        ArrowUp: ['rx', 'rot', -1],
        ArrowDown: ['rx', 'rot', 1],
        q: ['ry', 'rot', -1],
        Q: ['ry', 'rot', -1],
        e: ['ry', 'rot', 1],
        E: ['ry', 'rot', 1],
    };

    if (event.key === 'z' || event.key === 'Z') {
        event.preventDefault();
        nui('rotatePed', { delta: -8 });
        return;
    }
    if (event.key === 'c' || event.key === 'C') {
        event.preventDefault();
        nui('rotatePed', { delta: 8 });
        return;
    }
    if (event.key === 'Enter') {
        event.preventDefault();
        nui('save', state.attach);
        return;
    }
    if (event.key === 'Escape') {
        event.preventDefault();
        nui('cancel');
        return;
    }

    const bind = map[event.key];
    if (bind) {
        event.preventDefault();
        nudge(bind[0], bind[1], bind[2]);
    }
});

window.addEventListener('keyup', (event) => {
    if (!state.open) return;
    if (event.key === 'Shift' || event.key === 'Control') state.heldStep = null;
});

renderAxes();
nui('ready');

if (!inGame) {
    document.body.classList.add('preview');
    openEditor({
        label: 'Neon Pink Wings',
        slot: 'wings',
        maxOffset: 0.85,
        bones: [
            { id: 24818, name: 'Spine3 (upper back)' },
            { id: 64729, name: 'Left clavicle' },
            { id: 10706, name: 'Right clavicle' },
        ],
        attach: { ...PREVIEW_DEFAULT },
        steps: state.steps,
    });
}
