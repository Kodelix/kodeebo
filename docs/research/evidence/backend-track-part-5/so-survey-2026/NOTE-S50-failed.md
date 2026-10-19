# S50 - Egypt split of the Stack Overflow survey (FAILED, kept as record)
Date 2026-10-18. Commands run (curl, from docs/research/evidence/backend-track-part-5/so-survey-2026/):
1. `curl -sS https://survey.stackoverflow.co/ -o landing.html` (74450 bytes): no dataset link in the HTML (only a `DataDownload` schema token).
2. `curl -sSI https://survey.stackoverflow.co/datasets/stack-overflow-developer-survey-2026.zip` and `...-2025.zip`: both HTTP/2 404.
The URL pattern was a guess from memory and is wrong or moved. Result: no dataset downloaded, no Egypt count computed.
Label: wrong guess of URL - see F503.
