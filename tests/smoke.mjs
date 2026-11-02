import { spawnSync } from "node:child_process";
import {
  mkdtempSync,
  writeFileSync,
  readFileSync,
  existsSync,
  rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import assert from "node:assert/strict";
const binary = resolve(process.argv[2]);
const dir = mkdtempSync(join(tmpdir(), "axure-skill-smoke-"));
let count = 0;
function run(args, expected = 0) {
  const r = spawnSync(binary, args, {
    cwd: dir,
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: "/usr/bin:/bin:/usr/sbin:/sbin",
      PYTHONPATH: "",
      PYTHONHOME: "",
      VIRTUAL_ENV: "",
    },
    timeout: 120000,
  });
  assert.equal(
    r.status,
    expected,
    `${args.join(" ")}\n${r.stderr}\n${r.stdout}`,
  );
  count++;
  return JSON.parse(r.stdout);
}
try {
  const p = run([
    "project",
    "create",
    "--name",
    "测试",
    "--first-page",
    "首页",
    "--output",
    "base.rp",
  ]).result;
  assert.equal(p.format_version, 9);
  const scope = p.pages[0].scope_id;
  const page = p.pages[0].id;
  let current = "base.rp";
  let n = 0;
  function edit(domain, args) {
    const output = `step-${++n}.rp`;
    const data = run([
      ...domain,
      "--project",
      current,
      ...args,
      "--output",
      output,
    ]).result;
    current = output;
    return data;
  }
  const button = edit(
    ["node", "create"],
    [
      "--scope-id",
      scope,
      "--spec",
      JSON.stringify({
        kind: "button",
        name: "提交按钮",
        text: "提交",
        bounds: { x: 40, y: 40, width: 120, height: 40 },
      }),
    ],
  );
  const node = button.node_id;
  assert.ok(node);
  const found = run([
    "search",
    "explore",
    "--project",
    current,
    "--query",
    "提交",
    "--category",
    "instance",
    "--limit",
    "5",
  ]).result.items;
  assert.ok(found.some((x) => x.node_id === node));
  const panel = edit(
    ["panel", "create"],
    [
      "--scope-id",
      scope,
      "--bounds",
      '{"x":40,"y":100,"width":400,"height":240}',
      "--states",
      '["概览","详情"]',
      "--name",
      "内容面板",
    ],
  );
  assert.ok(panel.node_id);
  const events = [
    {
      event: "click",
      cases: [
        {
          actions: [
            {
              kind: "set_panel_state",
              params: { panel: panel.node_id, state: "详情" },
            },
          ],
        },
      ],
    },
  ];
  edit(
    ["interaction", "set"],
    [
      "--scope-id",
      scope,
      "--node-id",
      node,
      "--events",
      JSON.stringify(events),
    ],
  );
  const readEvents = run([
    "interaction",
    "get",
    "--project",
    current,
    "--scope-id",
    scope,
    "--node-id",
    node,
  ]).result;
  assert.equal(readEvents.length, 1);
  assert.equal(readEvents[0].cases[0].actions[0].kind, "set_panel_state");
  const repeater = edit(
    ["repeater", "create"],
    [
      "--scope-id",
      scope,
      "--bounds",
      '{"x":500,"y":100,"width":200,"height":40}',
      "--columns",
      '["Name"]',
      "--rows",
      '[{"Name":"Alpha"}]',
      "--name",
      "列表",
    ],
  );
  edit(
    ["repeater", "set-data"],
    [
      "--scope-id",
      scope,
      "--node-id",
      repeater.node_id,
      "--columns",
      '["Name"]',
      "--rows",
      '[{"Name":"Beta"}]',
    ],
  );
  const data = run([
    "repeater",
    "get-data",
    "--project",
    current,
    "--scope-id",
    scope,
    "--node-id",
    repeater.node_id,
  ]).result;
  assert.ok(JSON.stringify(data).includes("Beta"));
  edit(["page", "create"], ["--name", "详情"]);
  assert.equal(run(["page", "list", "--project", current]).result.length, 2);
  writeFileSync(
    join(dir, "ops.json"),
    JSON.stringify({
      schema_version: 2,
      operations: [
        {
          op: "node.update",
          params: {
            scope_id: scope,
            node_id: node,
            changes: { text: "确认提交" },
          },
        },
        { op: "page.rename", params: { page_id: page, name: "主页面" } },
      ],
    }),
  );
  const output = "batch.rp";
  run(["batch", "ops.json", "--project", current, "--output", output]);
  current = output;
  assert.equal(
    run([
      "node",
      "get",
      "--project",
      current,
      "--scope-id",
      scope,
      "--node-id",
      node,
    ]).result.text,
    "确认提交",
  );
  assert.equal(
    run(["project", "open", "--path", current]).result.pages[0].name,
    "主页面",
  );
  const before = readFileSync(join(dir, current));
  run(
    [
      "page",
      "create",
      "--project",
      current,
      "--name",
      "不应覆盖",
      "--output",
      current,
    ],
    2,
  );
  assert.deepEqual(readFileSync(join(dir, current)), before);
  writeFileSync(
    join(dir, "bad.json"),
    JSON.stringify({
      schema_version: 2,
      operations: [
        {
          op: "node.update",
          params: {
            scope_id: scope,
            node_id: node,
            changes: { text: "不应保存" },
          },
        },
        { op: "not.valid", params: {} },
      ],
    }),
  );
  const failed = run(
    ["batch", "bad.json", "--project", current, "--output", "failed.rp"],
    1,
  );
  assert.equal(failed.error.applied_count, 1);
  assert.equal(failed.error.failed_index, 1);
  assert.ok(!existsSync(join(dir, "failed.rp")));
  writeFileSync(
    join(dir, "index.html"),
    "<html><body><h1>商品详情</h1><button>立即购买</button></body></html>",
  );
  run(["html", "import", "index.html", "--output", "html.rp"]);
  assert.equal(
    run(["project", "open", "--path", "html.rp"]).result.format_version,
    9,
  );
  assert.ok(
    run([
      "search",
      "explore",
      "--project",
      "html.rp",
      "--query",
      "立即购买",
      "--limit",
      "5",
    ]).result.items.length,
  );
  console.log(
    JSON.stringify(
      {
        status: "PASS",
        commands: count,
        external_python: false,
        checks: [
          "create",
          "search",
          "panel",
          "interaction",
          "repeater",
          "multipage",
          "batch",
          "reopen",
          "overwrite",
          "batch-failure",
          "html-import",
        ],
        gui: "NOT_RUN",
      },
      null,
      2,
    ),
  );
} finally {
  rmSync(dir, { recursive: true, force: true });
}
