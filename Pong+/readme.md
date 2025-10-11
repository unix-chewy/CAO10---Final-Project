# 🕹️ Pong (x86 Assembly for DOSBox)

A simple Pong game written in x86 Assembly, designed to run inside **DOSBox**.

---

## ⚙️ Requirements
- **NASM** assembler  
- **DOSBox** emulator  
- (Optional) **FreeLink** linker (included with most DOS toolchains)

---

## 🧩 Installation & Setup

### 1️⃣ Install DOSBox
bash
sudo apt install dosbox

### 2️⃣ Assemble the Source Code
nasm -f obj pong.asm -o pong.obj

### 3️⃣ Run DOSBox and Mount Your Folder
mount c "[path_to_your_repo]"
c:

Replace [path_to_your_repo] with the full path to your Pong project folder. (or gawa ng separate folder but include both freelink.exe and pong.obj)

### 4️⃣ Link and Run the Game
freelink pong
pong
