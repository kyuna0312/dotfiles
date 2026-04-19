# security/aliases.zsh — Lucy Kushinada · netrunner security toolkit
# Sourced only when security tools (nmap/burpsuite) are detected

# ── Colors (Lucy Edgerunner+) ─────────────────────────────────────────────────
_S_PINK='\033[38;5;212m'
_S_CYAN='\033[38;5;51m'
_S_LAV='\033[38;5;183m'
_S_MINT='\033[38;5;158m'
_S_GOLD='\033[38;5;221m'
_S_ROSE='\033[38;5;204m'
_S_DIM='\033[38;5;239m'
_S_BOLD='\033[1m'
_S_RST='\033[0m'

# ── Network recon ─────────────────────────────────────────────────────────────
alias nse='nmap -sV --script=default'
alias nnmap='nmap -sn'
alias listen='ss -tulnp'              # renamed: lucy.zsh owns `ports`
alias myip='curl -s ifconfig.me'

# ── Web ───────────────────────────────────────────────────────────────────────
alias bsuite='burpsuite &>/dev/null &'
alias sqlm='sqlmap --batch'
alias nik='nikto -h'

# ── Password attacks ──────────────────────────────────────────────────────────
alias jtr='john --wordlist=/usr/share/wordlists/rockyou.txt'
alias hcat='hashcat -m'

# ── Reverse engineering ───────────────────────────────────────────────────────
alias ghidra-launch='ghidra &>/dev/null &'
alias r2='radare2'

# ── Capture ───────────────────────────────────────────────────────────────────
alias sniff='sudo tcpdump -i any -n'
alias sniffport='sudo tcpdump -i any -n port'

# ── CTF helpers ───────────────────────────────────────────────────────────────
b64d()          { echo "$1" | base64 -d; }
b64e()          { echo "$1" | base64; }
hexdump-clean() { xxd "$1" | less; }
rot13()         { echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'; }

# ── sectools: Lucy-styled reference card ─────────────────────────────────────
sectools() {
  printf "\n${_S_PINK}${_S_BOLD}  ✦  lucy kushinada · netrunner toolkit${_S_RST}\n"
  printf "${_S_DIM}     ──────────────────────────────────────${_S_RST}\n"
  printf "${_S_CYAN}     network   ${_S_RST}nmap, nse, nnmap, sniff, sniffport\n"
  printf "${_S_MINT}     recon     ${_S_RST}listen, myip, masscan\n"
  printf "${_S_LAV}     web       ${_S_RST}bsuite, sqlm, nik, ffuf, gobuster\n"
  printf "${_S_GOLD}     passwords ${_S_RST}jtr, hcat, hydra\n"
  printf "${_S_ROSE}     RE        ${_S_RST}ghidra-launch, r2, gdb, binwalk, exiftool\n"
  printf "${_S_DIM}     ctf       ${_S_RST}b64d, b64e, hexdump-clean, rot13\n"
  printf "${_S_DIM}     wordlist  ${_S_RST}/usr/share/wordlists/rockyou.txt\n"
  printf "${_S_DIM}     ──────────────────────────────────────${_S_RST}\n\n"
}
