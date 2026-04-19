# security/aliases.zsh
# Security research and pentest helpers
# Sourced only when security tools are detected

# ---------- Network recon ----------
alias nse='nmap -sV --script=default'          # service + default scripts
alias nnmap='nmap -sn'                          # ping sweep
alias ports='ss -tulnp'                         # listening ports (Linux)
alias myip='curl -s ifconfig.me'

# ---------- Web ----------
alias bsuite='burpsuite &>/dev/null &'          # launch burp in bg
alias sqlm='sqlmap --batch'
alias nik='nikto -h'

# ---------- Password attacks ----------
alias jtr='john --wordlist=/usr/share/wordlists/rockyou.txt'
alias hcat='hashcat -m'

# ---------- Reverse engineering ----------
alias ghidra-launch='ghidra &>/dev/null &'
alias r2='radare2'

# ---------- Capture ----------
alias sniff='sudo tcpdump -i any -n'
alias sniffport='sudo tcpdump -i any -n port'

# ---------- Helpers ----------
sectools() {
  echo "Network:  nmap, masscan, nse, nnmap, ports, myip, sniff, sniffport"
  echo "Web:      bsuite, sqlm, nik, ffuf, gobuster"
  echo "Passwords:jtr, hcat, hydra"
  echo "RE:       ghidra-launch, r2, gdb, binwalk, exiftool"
  echo "Wordlist: /usr/share/wordlists/rockyou.txt (Kali/BlackArch)"
}

# ---------- CTF helpers ----------
b64d() { echo "$1" | base64 -d; }
b64e() { echo "$1" | base64; }
hexdump-clean() { xxd "$1" | less; }

rot13() {
  echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}
