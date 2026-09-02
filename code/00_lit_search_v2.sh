#!/usr/bin/env bash
# 文献检索脚本 v2:PubMed (MEDLINE) via NCBI E-utilities
# 新检索式(四方辩论定案):暴露概念组 AND 结局概念组,无方法过滤词,无 governance
# 日期:2000-01-01 至 2026-08-14
set -e
OUTDIR="/Users/taozhu/my researches/lancet_financial_v3/submission"
mkdir -p "$OUTDIR"
cd "$OUTDIR"

QUERY='("government health expenditure"[tiab] OR "public health spending"[tiab] OR "health financing"[tiab] OR "public expenditure on health"[tiab] OR "public health expenditure"[tiab]) AND ("life expectancy"[tiab] OR "healthy life expectancy"[tiab] OR HALE[tiab] OR mortality[tiab] OR "all-cause mortality"[tiab] OR "population health"[tiab] OR "years of life lost"[tiab]) AND ("2000/01/01"[Date - Publication] : "2026/08/14"[Date - Publication])'

echo "=== E-utilities esearch v2 ===" > search_log_v2.txt
echo "查询式: $QUERY" >> search_log_v2.txt
echo "运行时间: $(date)" >> search_log_v2.txt

# 1) 计数
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$QUERY")&retmax=0&datetype=pdat" > esearch_count_v2.xml
COUNT=$(grep -o '<Count>[0-9]*</Count>' esearch_count_v2.xml | grep -o '[0-9]*')
echo "命中总数: $COUNT" >> search_log_v2.txt
echo "命中总数: $COUNT"

# 2) 取全部 PMID
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$QUERY")&retmax=1000&retmode=json" > esearch_v2.json
python3 - <<'EOF' > pubmed_pmids_v2.txt
import json
d = json.load(open("esearch_v2.json"))
ids = d["esearchresult"]["idlist"]
print("\n".join(ids))
EOF
echo "PMID 已写入 pubmed_pmids_v2.txt"

# 3) esummary 拉标题/摘要(分页 200/批)
python3 - <<'EOF'
import json, time, urllib.request, urllib.parse, os
ids = open("pubmed_pmids_v2.txt").read().split()
out = open("pubmed_records_v2.jsonl", "w")
for i in range(0, len(ids), 200):
    batch = ids[i:i+200]
    url = ("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed"
           "&id=" + ",".join(batch) + "&retmode=json")
    for attempt in range(3):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                d = json.load(r)
            break
        except Exception as e:
            if attempt == 2:
                print("FAIL batch", i, e, file=open("search_errors_v2.log","a"))
                d = None
            time.sleep(3)
    if d:
        for uid in d["result"].get("uids", []):
            rec = d["result"][uid]
            out.write(json.dumps({
                "pmid": uid,
                "title": rec.get("title",""),
                "journal": rec.get("fulljournalname",""),
                "pubdate": rec.get("pubdate",""),
            }, ensure_ascii=False) + "\n")
    time.sleep(0.5)
out.close()
print("记录已写入 pubmed_records_v2.jsonl")
EOF
echo "完成。见 $OUTDIR/pubmed_records_v2.jsonl"
