#!/bin/bash
# 鋼琴五線譜自動擷取工具 - Mac 一鍵啟動
# 第一次執行需要幾分鐘安裝套件；之後每次啟動都很快。

cd "$(dirname "$0")"

if ! command -v python3 &> /dev/null; then
  echo "找不到 Python3。"
  echo "請先到 https://www.python.org/downloads/ 安裝 Python 3.9 以上版本，再重新雙擊本檔案。"
  read -p "按 Enter 鍵結束..."
  exit 1
fi

# 如果偵測到不完整/損毀的虛擬環境 (例如上次執行中途被中斷)，先清掉重建，
# 避免卡在半殘的狀態一直失敗。
if [ -d "venv" ] && [ ! -x "venv/bin/python3" ]; then
  echo "偵測到不完整的虛擬環境，重新建立中..."
  rm -rf venv
fi

if [ ! -d "venv" ]; then
  echo "首次執行，正在建立虛擬環境..."
  python3 -m venv venv
fi

if [ ! -x "venv/bin/python3" ]; then
  echo ""
  echo "建立虛擬環境失敗。"
  echo "最常見的原因：這個資料夾所在的磁碟格式(常見於外接硬碟/網路磁碟機的 exFAT 或某些雲端同步磁碟)"
  echo "不支援 Python 虛擬環境需要的功能。"
  echo "建議：把整個工具資料夾複製到電腦內建硬碟(例如「文件」或「桌面」)後，再從那邊重新雙擊執行。"
  read -p "按 Enter 鍵結束..."
  exit 1
fi

# 注意：這裡刻意不用 "source venv/bin/activate" 再呼叫裸的 pip/python，
# 改成直接用完整路徑呼叫虛擬環境裡的執行檔——這樣就算 activate 沒有正確
# 把 venv/bin 加進 PATH (在某些外接磁碟/系統設定下曾發生過)，套件安裝跟
# 啟動伺服器還是會用到正確的虛擬環境，不會不小心跑到系統的 Python。
PY="./venv/bin/python3"

if [ ! -f "venv/.deps_installed" ]; then
  echo "正在安裝所需套件 (第一次執行需要幾分鐘)..."
  "$PY" -m pip install --upgrade pip --quiet --no-cache-dir
  if ! "$PY" -m pip install -r requirements.txt --quiet --no-cache-dir; then
    echo ""
    echo "安裝套件失敗，請往上捲動查看詳細錯誤訊息 (常見原因：網路連線不穩)。"
    echo "修好問題後可以重新雙擊本檔案再試一次。"
    read -p "按 Enter 鍵結束..."
    exit 1
  fi
  touch venv/.deps_installed
fi

echo ""
echo "正在啟動伺服器..."

# 等伺服器真的能連上了才自動開瀏覽器，避免電腦較慢時瀏覽器搶先開啟、
# 顯示「拒絕連線」——最多等 30 秒，還連不上的話請直接手動開瀏覽器輸入網址。
(
  for i in $(seq 1 30); do
    sleep 1
    if curl -s -o /dev/null "http://127.0.0.1:5002/" 2>/dev/null; then
      open "http://127.0.0.1:5002"
      exit 0
    fi
  done
) &

"$PY" app.py

read -p "伺服器已關閉，按 Enter 鍵結束..."
