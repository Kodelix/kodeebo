# Vendored: impeccable

| Field | Value |
|---|---|
| Source | https://github.com/pbakaus/impeccable |
| Tag | `skill-v4.5.2` (skill version 4.5.2, engine launcher 0.1.14) |
| Commit | `d631a8827f99414d2b6daba4ef08b7f8701751d7` |
| Vendored on | 2026-10-10 |
| License | Apache-2.0 — `LICENSE` and `NOTICE.md` in this folder |
| Plugin install | **None.** The marketplace plugin is deliberately not installed, so the skill and its hooks never run twice. |

## What was copied

- `.claude/skills/impeccable/` — the skill, its references and launcher scripts
- `.claude/agents/impeccable-{asset-producer,documenter,finish-reviewer,manual-edit-applier}.md`
- `settings.hooks.json` — upstream's hook wiring, kept for reference. **Only the PostToolUse (Edit|Write) hook is merged** into `.claude/settings.json` (decision 2026-10-10); SessionStart and the Stop deep pass are not.

## Runtime behaviour to know about

`skills/impeccable/scripts/impeccable` downloads a native engine binary from
`github.com/pbakaus/impeccable/releases` on first use, verifies its sha256, and
caches it per version. Upstream's hooks run that binary on SessionStart, after
every Edit/Write, and on Stop. Merging those hooks is a separate decision.

## Local modifications

None. Do not edit vendored files: integration with the studio (DoD gate, UI
agents, `/studio` routing) lives in studio files that *call* `/impeccable`.

## Updating

1. Pick a new upstream tag and read its changelog.
2. Sparse-clone only `/.claude/`, `LICENSE`, `NOTICE.md` at that tag.
3. Replace the copied paths above, update this table, and diff the checksum list below.

## Checksums (sha256)

```
854a2da0f67cbe627908aa450115e83985b7d20cf2cc345adf173f228c6130b8  agents/impeccable-asset-producer.md
6bc62a59f6fef0b749927c8d10e9849ab2411199d86d70772a86f8e83ac309f5  agents/impeccable-documenter.md
08398fa2d8e2b06b849f1c0f032e1e93b832e9294aed35c1c7f62b938d62ee80  agents/impeccable-finish-reviewer.md
b2d71ff0df7ed49e06dfc4acfce3d3f7eb48afa68be04763ee8c08354df50a07  agents/impeccable-manual-edit-applier.md
0648e4e06d01cabc91fa7dc19256ceedeeeea213b9265e9d36b0918370e16fb2  skills/impeccable/reference/adapt.md
17c583cf8ad41266ea1e787b666b9d91fe13469d3d0f6af57c08e0146f9b17ac  skills/impeccable/reference/adapt.native.md
058f81f256134841875fd3183e06b37a023de0c877fd2b9eecd97011640791fe  skills/impeccable/reference/android.md
94b4ce6299fea93d9f256b2d25705961a76bc5ea940c56db4145686ebc99df1b  skills/impeccable/reference/animate.md
b7c98bde47e00889c235e3d808b596224aad5a0869f25e439f135ce86551a075  skills/impeccable/reference/audit.md
fe91fcf28638f95577af481a50edaf339d6c9a3ad3b9fa477bc81c116b8bc392  skills/impeccable/reference/audit.native.md
4879f38b23d0a251a63cbb0327e660296194cd2e71eb4da3236c6ebfe5807746  skills/impeccable/reference/bolder.md
6c382f8283756e8a693d832b750f7e4cbff1ca5bdcc3825b2b4ef4da9f21876a  skills/impeccable/reference/clarify.md
d1fbd55074abb2251bdaa03749d34acc42c38e46e47549f18f5848df57d43c42  skills/impeccable/reference/colorize.md
6996198844d6459392b816e7bfb7d256f07b6884614e88069ffab5544b4886df  skills/impeccable/reference/component-review.md
96e2e6bd4fcf9a2c6da65fb029f96d9176308fae2efd9d8653d3b8d838960e07  skills/impeccable/reference/craft-floor.md
9205e222bc6565b37fb504ceec93233c2d2a456802b69d16e6b1c44723907c4c  skills/impeccable/reference/craft.md
c9284892cb1f21aaeaf93fdf2e9e7a679d05e0baa8ddf309a79a9790d262ad38  skills/impeccable/reference/critique.md
a83cfd24bf58bc8997540577651a485f1eca38fd324106d8bedeab2394fb169e  skills/impeccable/reference/degraded/asset-producer.md
bcc05ea92faebb5c74037a9d4263a5ce9a56f5ab07c8ab3c59ee704d8cade745  skills/impeccable/reference/degraded/documenter.md
275dd1b6e63bbd30d2713227c4f79b880a8bc4e01cc48d392068bb86939d3afa  skills/impeccable/reference/degraded/finish-reviewer.md
5fae7f8a2fc3ddd49ad0a413446dc44daedef5b6b7de5eb935bd2fbfad646d58  skills/impeccable/reference/degraded/manual-edit-applier.md
56500b1f9d2fcec8324d7f448d813048b5831a46d3feeb1055bd3eb17ec3660f  skills/impeccable/reference/delight.md
b2f60e0154bf0e687badc46d8c8420e2118a9a6e21162050722be779dc02cb6d  skills/impeccable/reference/distill.md
712a9a1cec93cc4d1bb4a4e9e47dd7c048973eebfa6f428f943386a7bc192f39  skills/impeccable/reference/doctor.md
87b3db688c7963898bda8096f7868fed05ec5a0a80d14298e8b906b70cdf9c42  skills/impeccable/reference/document.md
bfc51972fbf387566dc9e29c8b1af479a66ab401fdbce659fae9e6a5a9d85316  skills/impeccable/reference/extract.md
fc149b5bc7a8d0cc9b9bf86e5013793f3857c1c302212e9aaf101cb95427386b  skills/impeccable/reference/generate.md
3898bd9b56a042e860a0db4fb4dd81ac81126fa218b604702e2ac0c2287ae09b  skills/impeccable/reference/harden.md
3186f2c7fdf24c1fc9cc089850b62228fad79fde2908d3b6c900d9eda44b5185  skills/impeccable/reference/hooks.md
dc340befdfb87d1de3b70e860fab0be7e951a60d3ddc529072c39eb136cfcfcd  skills/impeccable/reference/init.md
40c87038b5f75147a5952a96237acf312a327bf70c1bcd8e0a5f064625ae9668  skills/impeccable/reference/ios.md
64802d14087fc96b38ef3881fef8098b36068d07f3b942031637b18eef3dd2af  skills/impeccable/reference/layout.md
b4def5b57733b6ba233570bd5691a536901f8b15479fc0111a2cde56224d0e1a  skills/impeccable/reference/live.md
6e7e3b7c4cf331cdb43f4546c164acd6c45a267ce3289dcfa87e13202d98c747  skills/impeccable/reference/live-setup.md
7a52dd7a94ee75f6ae89542c86a1b6e1d306812b16e0d9dbf12d4acad44d148b  skills/impeccable/reference/mode-operate.md
21e78c8a77badb3f83290cd4577ed3b24bd4dd3b57136d7da75733d4f3ee9ac0  skills/impeccable/reference/mode-persuade.md
a569989e6a3d6453b4c45e9474e162a15cc54e11732ac6baa7990a6e7cccc0b5  skills/impeccable/reference/mode-read.md
6c070f803553dfacbbb1a5e136d8a05776eee399bdd501d596dd513a6e7e7dbe  skills/impeccable/reference/new-work.md
9a2c08ee2516d2ee87129e7ebe6a0895f9990c9852d1f6fa7e70be9a6a88a659  skills/impeccable/reference/onboard.md
a9d2203acd45ca33a13d5c68b02b23ed512425ac15f0e8438318ed124b43729d  skills/impeccable/reference/operate.md
6d368b679a0ed1815812815de65863b5840d419589dfbda06224c01149240287  skills/impeccable/reference/optimize.md
a9856cb40da6519b1334bcfc75a4fbe83bef39ca86ee6f3effcb2a96794c627c  skills/impeccable/reference/overdrive.md
b8d49a3cab3428d9f351502e9c2c5802cef187e0d2af626ef3e1cd1837fd06bf  skills/impeccable/reference/polish.md
ee6d6d127c1c2ab3526d529a8e3698be2185b5e346ac617f37501de2c0698b97  skills/impeccable/reference/quieter.md
4ea8e05d0f88d24f182ad554da84317f90b9730e29fad262143ddf423a1f8645  skills/impeccable/reference/region-map.md
56285b28b0ffe471761c2ad062d3f933ed2346ca1b617f1323a30fed99a1a852  skills/impeccable/reference/routing.md
a55f016c046cb6a27c55bd7f346375aeb506a755c4fbca19a5f92dbd42309c23  skills/impeccable/reference/shape.md
696c15f96d49a03091b71a408151a3297521f7a8231b98ca9b1103667a0b5f89  skills/impeccable/reference/typeset.md
d685c04013b4559504db064a2c5a3e5868f24f7136b2b4f76f9d5f68086e779d  skills/impeccable/reference/visualize.md
e8720f3aa41135211cc58cc299a39eeda86c75651f4279cc1ede8db10dcc0584  skills/impeccable/scripts/command-metadata.json
835f19a0a3812f3652dd6979a2ce5597f654fd01f26e1b420b92d5f42b997ce4  skills/impeccable/scripts/data/font-index-failures.json
47edbdfaf27073c47033d1ac7dfee881be49e2dcbda7671d1157300481dde6da  skills/impeccable/scripts/data/font-index.json
39d9600489073e227e4f4d55c451ce4252a6632ed7ae37923efbbcbc91f16d07  skills/impeccable/scripts/impeccable
69cad1ae7355825ef320ac9638a1c9675ba9fda01c9a0fa12244cc4a1973e550  skills/impeccable/scripts/impeccable.cmd
24f09f2597b9b55a1e2c4acd2ae5c95db5c8615cfc20aa07d1a3950538ad5c4a  skills/impeccable/scripts/live-browser-dom.js
c1cb6877ca99a0c1b38ba0c7d59f32702d3022f6821d8045f7133f7c40b6362f  skills/impeccable/scripts/live-browser-ignores.js
d7f1ee3fdfc423e90268e9c666dce61b2180b62431dbb6ecfc48bca65398a1f8  skills/impeccable/scripts/live-browser.js
42831c3cd874346d8e7f120808d91e6ed3cda5c3eca6eefd76b126659536bc87  skills/impeccable/scripts/live-browser-session.js
bb36665889124a0b6e15f16045265737449c3bdcf2712cdb08af3cfa01563e2b  skills/impeccable/scripts/modern-screenshot.umd.js
9940d4b5219de8404015bc18af844c88d7e9e9105682a5d47b1d369d027dbd25  skills/impeccable/scripts/VERSION
35c883046117a416ca008ad7cbcda912c728a01f99b9a88130c2f0ab4c8d234c  skills/impeccable/SKILL.md
```
