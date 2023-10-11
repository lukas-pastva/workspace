# workspace
- Remote environment

- CamelCase in bash:
```bash
str="name-surname-forename-and-another-name"
echo "${str//-/ }" | while read -a words; do for word in "${words[@]}"; do printf "%s" "${word^}"; done; done 
```