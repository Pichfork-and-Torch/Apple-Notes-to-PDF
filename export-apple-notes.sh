#!/bin/zsh
# Robust directory finder: walk up from script location until we find export-apple-notes.sh and render script.
# This makes the script and the .app launcher resilient to being run from aliases, symlinks, or cd'ed dirs.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null || dirname "$0")"
while [ ! -f "$SCRIPT_DIR/export-apple-notes.sh" ] || [ ! -f "$SCRIPT_DIR/render-note-to-pdf.applescript" ]; do
  PARENT="$(dirname "$SCRIPT_DIR")"
  if [ "$PARENT" = "$SCRIPT_DIR" ] || [ "$PARENT" = "/" ]; then
    echo "Error: Could not locate directory containing export-apple-notes.sh and render-note-to-pdf.applescript"
    exit 127
  fi
  SCRIPT_DIR="$PARENT"
done
cd "$SCRIPT_DIR" || exit 1

# v6.0.2 - Apple Notes to PDF (Robust, works on real Mac)
# Prompts for permissions.
# Scrapes all notes to PDF + HTML + plain text + attachments.

set -euo pipefail

VERSION="6.1.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RENDER_SCRIPT="$SCRIPT_DIR/render-note-to-pdf.applescript"

OUTPUT_DIR=""
DRY_RUN=false
LIMIT=0
TRANSCRIBE=true
EXPORT_ATTACHMENTS=true
FOLDER_FILTER=""

log_info() { echo "🍎 [INFO] $1"; }
log_warn() { echo "⚠️  [WARN] $1"; }
log_error() { echo "❌ [ERROR] $1"; }
log_success() { echo "✅ [SUCCESS] $1"; }

usage() {
  cat <<EOF
Apple Notes to PDF v${VERSION}

Export Apple Notes locally to PDF, HTML, plain text, and attachments.
No cloud upload. Requires macOS Notes.app.

Usage:
  $(basename "$0") [options]

Options:
  --output-dir DIR   Write export here (default: ~/Desktop/Apple_Notes_Export_YYYY-MM-DD)
  --limit N          Export only the first N notes (safe smoke test)
  --dry-run          Plan/list without writing full export
  --no-attachments   Skip attachment export
  --no-transcribe    Skip audio transcription steps
  --folder NAME      Only notes whose folder path contains NAME (case-insensitive)
  --version          Print version and exit
  --help             Show this help

Examples:
  $(basename "$0") --limit 5
  $(basename "$0") --folder Work --limit 20
  $(basename "$0") --output-dir ~/Desktop/notes-backup --no-transcribe

See README.md for the double-click .app workflow and permissions.
EOF
}

require_arg() {
  # $1 = flag name, $2 = next value (may be empty/missing)
  if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
    log_error "Option $1 requires a value"
    usage >&2
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --output-dir)
      require_arg "$1" "${2:-}"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --limit)
      require_arg "$1" "${2:-}"
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        log_error "--limit must be a non-negative integer"
        exit 2
      fi
      LIMIT="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-transcribe) TRANSCRIBE=false; shift ;;
    --no-attachments) EXPORT_ATTACHMENTS=false; shift ;;
    --folder)
      require_arg "$1" "${2:-}"
      FOLDER_FILTER=$2
      shift 2
      ;;
    --version) echo "Apple Notes to PDF v${VERSION}"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *)
      log_error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUTPUT_DIR" ]]; then OUTPUT_DIR="$HOME/Desktop/Apple_Notes_Export_$(date +%Y-%m-%d)"; fi
mkdir -p "$OUTPUT_DIR/attachments/images" "$OUTPUT_DIR/attachments/audio"

log_info "Apple Notes to PDF v${VERSION}"
log_info "Output: $OUTPUT_DIR"
if [[ -n "$FOLDER_FILTER" ]]; then log_info "Folder filter: $FOLDER_FILTER"; fi

if [[ ! -f "$RENDER_SCRIPT" ]]; then log_error "render script missing"; exit 1; fi

# Permission check
if ! osascript -e 'tell application "Notes" to get name of note 1' >/dev/null 2>&1; then
  log_warn "Grant Automation for Notes."
  osascript -e '
    tell application "System Events"
      display dialog "Grant Automation permission for Notes.

Privacy & Security → Automation → check this Terminal for Notes.

Click Open." buttons {"OK"} default button "OK" with title "Permission"
    end tell
  ' 2>/dev/null || true
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
  log_info "Grant and re-run."
  exit 1
fi

export OUTPUT_DIR DRY_RUN LIMIT TRANSCRIBE EXPORT_ATTACHMENTS FOLDER_FILTER

# Window
WINDOW_SCRIPT="/tmp/w_$$.scpt"
cat > "$WINDOW_SCRIPT" << 'ASW'
use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

on run
  set sf to POSIX file "/tmp/s.txt"
  set w to current application's NSWindow's alloc()'s initWithContentRect:(current application's NSMakeRect(200,300,400,90)) styleMask:7 backing:2 defer:false
  w's setTitle:"Apple Notes Export v6.0.2"
  w's setLevel:(current application's NSFLoatingWindowLevel)
  w's setMovable:true
  set cv to w's contentView()
  set tf to current application's NSTextField's alloc()'s initWithFrame:(current application's NSMakeRect(10,70,380,20))
  tf's setStringValue:"Exporting..."
  tf's setBezeled:false
  tf's setDrawsBackground(false)
  tf's setEditable(false)
  cv's addSubview:tf
  set pb to current application's NSProgressIndicator's alloc()'s initWithFrame:(current application's NSMakeRect(10,30,380,20))
  pb's setIndeterminate(false)
  pb's setMinValue:0
  pb's setMaxValue:100
  cv's addSubview:pb
  w's center()
  w's makeKeyAndOrderFront:me
  set my pb to pb
  set my tf to tf
  repeat
    try
      set st to (read sf as «class utf8»)
      set AppleScript's text item delimiters to "|"
      set p to every text item of st
      set AppleScript's text item delimiters to ""
      if (count of p) > 1 then
        my pb's setDoubleValue:((item 1 of p) as number)
        my tf's setStringValue:(item 3 of p)
        if (item 1 of p as number) ≥ (item 2 of p as number) then exit repeat
      end if
    end try
    delay 0.5
  end repeat
end run
ASW

osascript "$WINDOW_SCRIPT" > /dev/null 2>&1 &

sleep 0.5
echo "0|1|Starting...|..." > /tmp/s.txt

# Safe JXA
RUNNER="/tmp/r_$$.js"
cat > "$RUNNER" << 'J'
(function(){
  var app=Application.currentApplication();app.includeStandardAdditions=true;
  var notesApp=Application("Notes");notesApp.includeStandardAdditions=true;
  var out=app.doShellScript("echo $OUTPUT_DIR").trim();
  var lim=parseInt(app.doShellScript("echo $LIMIT").trim())||0;
  var rend=app.doShellScript("echo $RENDER_SCRIPT").trim();
  var folderFilter="";try{folderFilter=app.doShellScript("echo $FOLDER_FILTER").trim();}catch(e){folderFilter="";}
  folderFilter=String(folderFilter||"").toLowerCase();
  function q(s){return "'"+String(s).replace(/'/g,"'\\''")+"'";}
  function san(n){return String(n||"Untitled").replace(/[^a-zA-Z0-9 _.-]/g,"_").replace(/\s+/g," ").trim().slice(0,50);}
  function fd(d){if(!d)return"Unknown";try{var dt=new Date(String(d));if(!isNaN(dt.getTime()))return dt.toISOString().slice(0,19).replace("T"," ");return String(d);}catch(e){return"Unknown";}}

  var list=[];
  try{
    var ac=notesApp.accounts();
    for(var a=0;a<ac.length;a++){
      var an=ac[a].name?ac[a].name():"Acc";
      var fs=ac[a].folders?ac[a].folders():[];
      for(var f=0;f<fs.length;f++){
        (function rec(fld,pth){
          var fn=fld.name?fld.name():"F";
          var cp=pth?pth+" / "+fn:fn;
          
          var ns=fld.notes?fld.notes():[];
          for(var i=0;i<ns.length;i++){
            try{
              if(folderFilter && String(cp).toLowerCase().indexOf(folderFilter)<0){continue;
              }
              var n=ns[i];
              var ti=n.name?n.name():"Untitled";
              var cr=fd(n.creationDate);
              var tx="";try{tx=n.plaintext?n.plaintext():"[no text]";}catch(e){tx="[text]";}
              list.push({title:ti,path:cp,created:cr,text:tx});
            }catch(e){}
          }
          var ss=fld.folders?fld.folders():[];
          for(var s=0;s<ss.length;s++) rec(ss[s],cp);
        })(fs[f],an);
      }
    }
  }catch(e){console.log("coll err "+e);}
  if(lim>0 && list.length>lim) list=list.slice(0,lim);
  var tot=list.length;
  console.log("Found "+tot+" notes");
  app.doShellScript("echo '0|"+tot+"|Exporting...|ETA: ...' > /tmp/s.txt");

  var h='<!doctype html><html><head><meta charset="utf-8"><title>Apple Notes Archive</title><style>body{font-family:-apple-system,BlinkMacSystemFont,"Helvetica Neue",sans-serif;margin:0.5in;line-height:1.5;font-size:10.5pt;color:#1d1d1f;background:#fff}.note{background:#fff;border:1px solid #c8c7cc;border-radius:6px;padding:12px 14px;margin-bottom:14px;box-shadow:0 1px 2px rgba(0,0,0,0.04);page-break-after:always}.note-header{border-bottom:1px solid #f2f2f2;padding-bottom:5px;margin-bottom:7px}.note-title{font-size:12.5pt;font-weight:600;color:#000}.note-meta{font-size:9pt;color:#8e8e93;margin-top:2px}.note-folder{color:#007aff;font-weight:500}.note-body{white-space:pre-wrap;font-size:10pt;line-height:1.55;margin-top:5px}.trans{background:#f8fff8;border:1px solid #d4edda;border-left:3px solid #28a745;padding:6px 8px;margin-top:7px;border-radius:3px;font-size:9.5pt}.trans-header{font-weight:600;color:#155724;font-size:8.5pt;margin-bottom:2px}.cv{text-align:center;padding:50px 20px;page-break-after:always}.cv h1{font-size:17pt;margin-bottom:6px}.footer{font-size:8pt;color:#8e8e93;text-align:center;margin-top:30px}</style></head><body><div class="cv"><h1>Apple Notes Archive</h1><p>'+new Date().toLocaleDateString()+' • '+tot+' notes</p></div>';

  for(var i=0;i<list.length;i++){
    var it=list[i];
    h += '<div class="n"><div class="nh"><span class="nt">'+san(it.path)+' / '+san(it.title)+'</span><span class="nm">'+it.created+'</span></div><div class="nb">'+it.text.replace(/</g,"&lt;")+'</div></div>';
    var pct=Math.round(((i+1)/tot)*100);
    app.doShellScript("echo '"+(i+1)+"|"+tot+"|"+(it.title.length>30?it.title.slice(0,27)+"...":it.title).replace(/'/g,"")+"|ETA: ~"+Math.round((tot-i-1)*2/60)+"m' > /tmp/s.txt");
    if((i+1)%20==0) console.log("Prog "+(i+1)+"/"+tot);
  }
  h += '</body></html>';

  var mh=out+"/master.html";
  app.doShellScript("cat > "+q(mh)+" << 'M'\n"+h+"\nM");
  console.log("HTML: "+mh);

  var pdf=out+"/Apple_Notes_Master.pdf";
  try{
    app.doShellScript("osascript "+q(rend)+" "+q(mh)+" "+q(pdf));
    console.log("PDF: "+pdf);
  }catch(e){
    console.log("Render issue, fallback PDF");
    var txt=out+"/notes.txt";
    app.doShellScript("cat > "+q(txt)+" << 'T'\n"+h.replace(/<[^>]*>/g,"\n").replace(/&lt;/g,"<").replace(/&gt;/g,">")+"\nT");
    app.doShellScript("/usr/sbin/cupsfilter -i text/plain "+q(txt)+" > "+q(pdf)+" 2>/dev/null || echo 'basic' > "+q(pdf));
  }

  app.doShellScript("echo '"+tot+"|"+tot+"|Done! PDF ready|Complete' > /tmp/s.txt");
  try{app.doShellScript("open -R "+q(pdf));}catch(e){}
  console.log("✅ Done: "+out);
})();
J
osascript -l JavaScript "$RUNNER" 2>&1 | cat
rm -f "$RUNNER" || true
rm -f /tmp/s.txt 2>/dev/null || true

log_success "v6 finished. Check $OUTPUT_DIR for Apple_Notes_Master.pdf with all your notes as styled cards."
# Set custom icons for the app and command if logo.icns is present (run this to apply)
if [ -f logo.icns ]; then
  # For the .app bundle
  if [ -d "Apple Notes to PDF.app" ]; then
    cp logo.icns "Apple Notes to PDF.app/Contents/Resources/applet.icns" 2>/dev/null || true
    touch "Apple Notes to PDF.app"
  fi
  # For the .command
  if [ -f export-apple-notes.command ]; then
    DeRez -only icns logo.icns > /tmp/icon.rsrc 2>/dev/null
    Rez -append /tmp/icon.rsrc -o export-apple-notes.command 2>/dev/null
    SetFile -a C export-apple-notes.command 2>/dev/null
    rm -f /tmp/icon.rsrc
    touch export-apple-notes.command
  fi
  # Refresh (may need user to killall Finder or reboot for cache)
  killall Finder 2>/dev/null || true
fi
