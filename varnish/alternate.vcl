vcl 4.0;
C{
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <pthread.h>
static pthread_mutex_t lrand_mutex = PTHREAD_MUTEX_INITIALIZER;
void generate_uuid(char* buf) {
pthread_mutex_lock(&lrand_mutex);
long a = lrand48();
long b = lrand48();
long c = lrand48();
long d = lrand48();
pthread_mutex_unlock(&lrand_mutex);
sprintf(buf, "frontend=%08lx%04lx%04lx%04lx%04lx%08lx",
a,
b & 0xffff,
(b & ((long)0x0fff0000) >> 16) | 0x4000,
(c & 0x0fff) | 0x8000,
(c & (long)0xffff0000) >> 16,
d
);
return;
}
}C
import std;
import directors;
backend default {
.host = "127.0.0.1";
.port = "8080";
.first_byte_timeout = 300s;
.between_bytes_timeout = 300s;
}
backend admin {
.host = "127.0.0.1";
.port = "8080";
.first_byte_timeout = 21600s;
.between_bytes_timeout = 21600s;
}
acl crawler_acl {
"127.0.0.1";
}
acl debug_acl {
}
/* -- REMOVED
sub generate_session {
if (req.url ~ ".*[&?]SID=([^&]+).*") {
set req.http.X-Varnish-Faked-Session = regsub(
req.url, ".*[&?]SID=([^&]+).*", "frontend=\1");
} else {
C{
char uuid_buf [50];
generate_uuid(uuid_buf);
static const struct gethdr_s VGC_HDR_REQ_VARNISH_FAKED_SESSION =
{ HDR_REQ, "\030X-Varnish-Faked-Session:"};
VRT_SetHdr(ctx,
&VGC_HDR_REQ_VARNISH_FAKED_SESSION,
uuid_buf,
vrt_magic_string_end
);
}C
}
if (req.http.Cookie) {
std.collect(req.http.Cookie);
set req.http.Cookie = req.http.X-Varnish-Faked-Session +
"; " + req.http.Cookie;
} else {
set req.http.Cookie = req.http.X-Varnish-Faked-Session;
}
}
sub generate_session_expires {
C{
time_t now = time(NULL);
struct tm now_tm = *gmtime(&now);
now_tm.tm_sec += 3600;
mktime(&now_tm);
char date_buf [50];
strftime(date_buf, sizeof(date_buf)-1, "%a, %d-%b-%Y %H:%M:%S %Z", &now_tm);
static const struct gethdr_s VGC_HDR_RESP_COOKIE_EXPIRES =
{ HDR_RESP, "\031X-Varnish-Cookie-Expires:"};
VRT_SetHdr(ctx,
&VGC_HDR_RESP_COOKIE_EXPIRES,
date_buf,
vrt_magic_string_end
);
}C
}
-- */
sub vcl_synth {
if (resp.status == 750) {
set resp.status = 301;
set resp.http.Location = "https://" + req.http.host + req.url;
return(deliver);
}
}
sub vcl_init {
}
sub vcl_recv {
if (req.restarts == 0) {
if (req.http.X-Forwarded-For) {
set req.http.X-Forwarded-For =
req.http.X-Forwarded-For + ", " + client.ip;
} else {
set req.http.X-Forwarded-For = client.ip;
}
}
if (!true || req.http.Authorization ||
req.method !~ "^(GET|HEAD|OPTIONS)$" ||
req.http.Cookie ~ "varnish_bypass=1") {
return (pass);
}
if(false) {
set req.http.X-Varnish-Origin-Url = req.url;
}
set req.url = regsuball(req.url, "(.*)//+(.*)", "\1/\2");
if (req.http.Accept-Encoding) {
if (req.http.Accept-Encoding ~ "\*|gzip") {
set req.http.Accept-Encoding = "gzip";
} else if (req.http.Accept-Encoding ~ "deflate") {
set req.http.Accept-Encoding = "deflate";
} else {
unset req.http.Accept-Encoding;
}
}
if (req.url ~ "^(/media/|/skin/|/js/|/)(?:(?:index|litespeed)\.php/)?") {
set req.http.X-Turpentine-Secret-Handshake = "1";
if (req.url ~ "^(/media/|/skin/|/js/|/)(?:(?:index|litespeed)\.php/)?admin") {
set req.backend_hint = admin;
return (pipe);
} else {
}
if (req.http.Cookie ~ "\bcurrency=") {
set req.http.X-Varnish-Currency = regsub(
req.http.Cookie, ".*\bcurrency=([^;]*).*", "\1");
}
if (req.http.Cookie ~ "\bstore=") {
set req.http.X-Varnish-Store = regsub(
req.http.Cookie, ".*\bstore=([^;]*).*", "\1");
}
if (req.url ~ "/turpentine/esi/get(?:Block|FormKey)/") {
set req.http.X-Varnish-Esi-Method = regsub(
req.url, ".*/method/(\w+)/.*", "\1");
set req.http.X-Varnish-Esi-Access = regsub(
req.url, ".*/access/(\w+)/.*", "\1");
if (req.http.X-Varnish-Esi-Method == "esi" && req.esi_level == 0 &&
!(false || client.ip ~ debug_acl)) {
return (synth(403, "External ESI requests are not allowed"));
}
}
if (req.http.Cookie !~ "frontend=" && !req.http.X-Varnish-Esi-Method) {
if (client.ip ~ crawler_acl ||
req.http.User-Agent ~ "^(?:ApacheBench/.*|.*Googlebot.*|JoeDog/.*|.*Siege/.*|magespeedtest\.com|Nexcessnet_Turpentine/.*|.*PTST.*)$") {
set req.http.Cookie = "frontend=crawler-session";
} else {
return (pipe);
}
}
if (true &&
req.url ~ ".*\.(?:css|js|jpe?g|png|gif|ico|swf)(?=\?|&|$)") {
unset req.http.Cookie;
unset req.http.X-Varnish-Faked-Session;
set req.http.X-Varnish-Static = 1;
return (hash);
}
if (req.url ~ "^(/media/|/skin/|/js/|/)(?:(?:index|litespeed)\.php/)?(?:admin|api|cron\.php)" ||
req.url ~ "\?.*__from_store=") {
return (pipe);
}
if (true &&
req.url ~ "(?:[?&](?:__SID|XDEBUG_PROFILE)(?=[&=]|$))") {
return (pass);
}
if (req.url ~ "[?&](utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=") {
set req.url = regsuball(req.url, "(?:(\?)?|&)(?:utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=[^&]+", "\1");
set req.url = regsuball(req.url, "(?:(\?)&|\?$)", "\1");
}
if (true && req.url ~ "[?&](utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|cx|ie|cof|siteurl)=") {
set req.url = regsuball(req.url, "(?:(\?)?|&)(?:utm_source|utm_medium|utm_campaign|utm_content|utm_term|gclid|cx|ie|cof|siteurl)=[^&]+", "\1");
set req.url = regsuball(req.url, "(?:(\?)&|\?$)", "\1");
}
if(false) {
set req.http.X-Varnish-Cache-Url = req.url;
set req.url = req.http.X-Varnish-Origin-Url;
unset req.http.X-Varnish-Origin-Url;
}
return (hash);
}
}
sub vcl_pipe {
unset bereq.http.X-Turpentine-Secret-Handshake;
set bereq.http.Connection = "close";
}
sub vcl_hash {
std.log("vcl_hash start");
if (true && req.http.X-Varnish-Static) {
std.log("hash_data static file - req.url: " + req.url);
hash_data(req.url);
if (req.http.Accept-Encoding) {
std.log("hash_data static file - Accept-Encoding: " + req.http.Accept-Encoding);
hash_data(req.http.Accept-Encoding);
}
std.log("vcl_hash end return lookup");
return (lookup);
}
if(false && req.http.X-Varnish-Cache-Url) {
hash_data(req.http.X-Varnish-Cache-Url);
std.log("hash_data - X-Varnish-Cache-Url: " + req.http.X-Varnish-Cache-Url);
} else {
hash_data(req.url);
std.log("hash_data - req.url: " + req.url );
}
if (req.http.Host) {
hash_data(req.http.Host);
std.log("hash_data - req.http.Host: " + req.http.Host);
} else {
hash_data(server.ip);
}
std.log("hash_data - req.http.Ssl-Offloaded: " + req.http.Ssl-Offloaded);
hash_data(req.http.Ssl-Offloaded);
if (req.http.X-Normalized-User-Agent) {
hash_data(req.http.X-Normalized-User-Agent);
std.log("hash_data - req.http.X-Normalized-User-Agent: " + req.http.X-Normalized-User-Agent);
}
if (req.http.Accept-Encoding) {
hash_data(req.http.Accept-Encoding);
std.log("hash_data - req.http.Accept-Encoding: " + req.http.Accept-Encoding);
}
if (req.http.X-Varnish-Store || req.http.X-Varnish-Currency) {
hash_data("s=" + req.http.X-Varnish-Store + "&c=" + req.http.X-Varnish-Currency);
std.log("hash_data - Store and Currency: " + "s=" + req.http.X-Varnish-Store + "&c=" + req.http.X-Varnish-Currency);
}
if (req.http.X-Varnish-Esi-Access == "private" &&
req.http.Cookie ~ "frontend=") {
std.log("hash_data - frontned cookie: " + regsub(req.http.Cookie, "^.*?frontend=([^;]*);*.*$", "\1"));
hash_data(regsub(req.http.Cookie, "^.*?frontend=([^;]*);*.*$", "\1"));
}
std.log("vcl_hash end return lookup");
if (req.http.X-Varnish-Esi-Access == "customer_group" &&
req.http.Cookie ~ "customer_group=") {
hash_data(regsub(req.http.Cookie, "^.*?customer_group=([^;]*);*.*$", "\1"));
}
return (lookup);
}
sub vcl_hit {
}
sub vcl_backend_response {
set beresp.grace = 15s;
set beresp.http.X-Varnish-Host = bereq.http.host;
set beresp.http.X-Varnish-URL = bereq.url;
if (bereq.url ~ "^(/media/|/skin/|/js/|/)(?:(?:index|litespeed)\.php/)?") {
unset beresp.http.Vary;
set beresp.do_gzip = true;
if (beresp.status != 200 && beresp.status != 404) {
set beresp.ttl = 15s;
set beresp.uncacheable = true;
return (deliver);
} else {
if (beresp.http.Set-Cookie) {
set beresp.http.X-Varnish-Set-Cookie = beresp.http.Set-Cookie;
unset beresp.http.Set-Cookie;
}
unset beresp.http.Cache-Control;
unset beresp.http.Expires;
unset beresp.http.Pragma;
unset beresp.http.Cache;
unset beresp.http.Age;
if (beresp.http.X-Turpentine-Esi == "1") {
set beresp.do_esi = true;
}
if (beresp.http.X-Turpentine-Cache == "0") {
set beresp.ttl = 15s;
set beresp.uncacheable = true;
return (deliver);
} else {
if (true &&
bereq.url ~ ".*\.(?:css|js|jpe?g|png|gif|ico|swf)(?=\?|&|$)") {
set beresp.ttl = 28800s;
set beresp.http.Cache-Control = "max-age=28800";
} elseif (bereq.http.X-Varnish-Esi-Method) {
if (bereq.http.X-Varnish-Esi-Access == "private" &&
bereq.http.Cookie ~ "frontend=") {
set beresp.http.X-Varnish-Session = regsub(bereq.http.Cookie,
"^.*?frontend=([^;]*);*.*$", "\1");
}
if (bereq.http.X-Varnish-Esi-Method == "ajax" &&
bereq.http.X-Varnish-Esi-Access == "public") {
set beresp.http.Cache-Control = "max-age=" + regsub(
bereq.url, ".*/ttl/(\d+)/.*", "\1");
}
set beresp.ttl = std.duration(
regsub(
bereq.url, ".*/ttl/(\d+)/.*", "\1s"),
300s);
if (beresp.ttl == 0s) {
set beresp.ttl = 15s;
set beresp.uncacheable = true;
return (deliver);
}
} else {
set beresp.ttl = 3600s;
}
}
}
return (deliver);
}
}
sub vcl_deliver {
if (req.http.X-Varnish-Faked-Session) {
set resp.http.Set-Cookie = req.http.X-Varnish-Faked-Session +
"; expires=" + resp.http.X-Varnish-Cookie-Expires + "; path=/";
if (req.http.Host) {
if (req.http.User-Agent ~ "^(?:ApacheBench/.*|.*Googlebot.*|JoeDog/.*|.*Siege/.*|magespeedtest\.com|Nexcessnet_Turpentine/.*|.*PTST.*)$") {
set resp.http.Set-Cookie = resp.http.Set-Cookie +
"; domain=" + regsub(req.http.Host, ":\d+$", "");
} else {
if (req.http.Host ~ "" && "" ~ "..") {
set resp.http.Set-Cookie = resp.http.Set-Cookie +
"; domain=";
} else {
set resp.http.Set-Cookie = resp.http.Set-Cookie +
"; domain=" + regsub(req.http.Host, ":\d+$", "");
}
}
}
set resp.http.Set-Cookie = resp.http.Set-Cookie + "; httponly";
unset resp.http.X-Varnish-Cookie-Expires;
}
if (req.http.X-Varnish-Esi-Method == "ajax" && req.http.X-Varnish-Esi-Access == "private") {
set resp.http.Cache-Control = "no-cache";
}
if (false || client.ip ~ debug_acl) {
set resp.http.X-Varnish-Hits = obj.hits;
set resp.http.X-Varnish-Esi-Method = req.http.X-Varnish-Esi-Method;
set resp.http.X-Varnish-Esi-Access = req.http.X-Varnish-Esi-Access;
set resp.http.X-Varnish-Currency = req.http.X-Varnish-Currency;
set resp.http.X-Varnish-Store = req.http.X-Varnish-Store;
} else {
unset resp.http.X-Varnish;
unset resp.http.Via;
unset resp.http.X-Powered-By;
unset resp.http.Server;
unset resp.http.X-Turpentine-Cache;
unset resp.http.X-Turpentine-Esi;
unset resp.http.X-Turpentine-Flush-Events;
unset resp.http.X-Turpentine-Block;
unset resp.http.X-Varnish-Session;
unset resp.http.X-Varnish-Host;
unset resp.http.X-Varnish-URL;
unset resp.http.X-Varnish-Set-Cookie;
}
}