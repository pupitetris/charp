package require md5
package require sha256
package require http
package require json
package require json::write

set BASEURL [lindex $argv 0]
set LOGIN [lindex $argv 1]
set PASSWD [lindex $argv 2]
set FUNC [lindex $argv 3]
set PARAMS [lindex $argv 4]

set http_tok [http::geturl $BASEURL/request -query [http::formatQuery login $LOGIN res $FUNC params $PARAMS] -keepalive 1]
upvar #0 $http_tok res

if {$res(status) != "ok"} {
    puts "Error HTTP en request"
    exit 1
}

catch {set s [json::json2dict $res(body)]} @
if {! [info exists s]} {
    puts "Error decode JSON en request"
    puts $@
    puts $res(body)
    exit 2
}

if [dict exists $s error] {
    puts "Error reportado en request"
    puts $res(body)
    exit 3
}

set chal [dict get $s chal]
set hash [string tolower [sha2::sha256 -hex $LOGIN$chal[string tolower [md5::md5 -hex $PASSWD]]]]

set http_tok [http::geturl $BASEURL/reply -query [http::formatQuery login $LOGIN chal $chal hash $hash] -keepalive 1]
upvar #0 $http_tok res

if {$res(status) != "ok"} {
    puts "Error HTTP en reply"
    exit 4
}

catch {set s2 [json::json2dict $res(body)]} @
if {! [info exists s2]} {
    puts "Error decode JSON en reply"
    puts $@
    puts $res(body)
    exit 5
}

if [dict exists $s2 error] {
    puts "Error reportado en reply"
    puts $res(body)
    exit 6
}

puts $res(body)
