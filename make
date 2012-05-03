git checkout build
git pull origin build
~/workspace/DCPU-16/DCPUToolchain/Debug/assembler -r -o terminal.obj terminal.dasm
git add *
git status
git commit -m "Automatic build commit."
git push origin build
