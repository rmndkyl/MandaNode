open Unix
open Yojson.Basic
open Cohttp_lwt_unix
open Lwt

let red s = "\027[31m" ^ s ^ "\027[0m"
let green s = "\027[32m" ^ s ^ "\027[0m"  
let yellow s = "\027[33m" ^ s ^ "\027[0m"
let blue s = "\027[34m" ^ s ^ "\027[0m"
let magenta s = "\027[35m" ^ s ^ "\027[0m"
let cyan s = "\027[36m" ^ s ^ "\027[0m"
(* need to change color in new version *)
let bold s = "\027[1m" ^ s ^ "\027[0m"
let dim s = "\027[2m" ^ s ^ "\027[0m"
let bg_red s = "\027[41m" ^ s ^ "\027[0m"
let bg_green s = "\027[42m" ^ s ^ "\027[0m"

let green_box s = 
let line = String.make (String.length s + 4) '=' in
"\n" ^ bg_green (line ^ "\n| " ^ s ^ " |\n" ^ line) ^ "\n"

let error_box s =
let line = String.make (String.length s + 4) '=' in
"\n" ^ bg_red (line ^ "\n| " ^ s ^ " |\n" ^ line) ^ "\n"

let success_box s =
let line = String.make (String.length s + 4) '*' in
"\n" ^ bg_green (line ^ "\n| " ^ s ^ " |\n" ^ line) ^ "\n"

let print_header s =
print_endline ("\n" ^ bold (cyan "╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸"));
print_endline (bold (cyan ("              " ^ s ^ "              ")));
print_endline (bold (cyan "╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸") ^ "\n")

let print_section s =
print_endline (yellow "\n→ " ^ bold s)

let print_success s = print_endline (green ("✓ " ^ s ^ "."))
let print_error s = print_endline (error_box ("ERROR: " ^ s ^ "."))
let print_info s = print_endline (dim (cyan ("ℹ " ^ s ^ "...")))
let print_warning s = print_endline (yellow ("⚠ " ^ s ^ "."))

let get_command_output cmd =
let ic = Unix.open_process_in cmd in
try
  let output = input_line ic in
  close_in ic;
  if String.trim output = "" then "N/A" else output
with End_of_file -> (
  close_in ic;
  "N/A"
)

let rec prompt_input prompt validate error_message =
print_string (cyan "→ " ^ bold prompt ^ ": ");
let input = read_line () in
if validate input then (
  print_success "Input successfully validated";
  print_endline "";
  input
) else (
  print_error error_message;
  prompt_input prompt validate error_message
)

let non_empty s = String.length (String.trim s) > 0
let is_email s = Str.string_match (Str.regexp "^[^@]+@[^@]+\\.[^@]+$") s 0
let is_number s =
try let n = int_of_string (String.trim s) in n >= 0 with _ -> false
let is_uptime s = 
try let n = int_of_string (String.trim s) in n > 0 && n <= 24 with _ -> false
let is_ip_type s = s = "static" || s = "non-static"
let is_yn s = s = "y" || s = "n"
let is_location s = Str.string_match (Str.regexp "^[A-Za-z]+, [A-Za-z]+$") s 0

let os_type =
print_info "Detecting operating system";
let uname = get_command_output "uname -s" in
let os = if String.trim uname = "Darwin" then "macOS" else "Linux" in
print_success ("Detected OS: " ^ os);
os

let () = print_header "Octra node configurator";;

let () = 
print_endline (cyan "Upon successful configuration, you will receive a configuration file");
print_endline (cyan "containing your unique validator hash. This file will be required");
print_endline (cyan "when launching your validator node.");
print_endline "";;

let () = print_section "Personal information";;
print_endline "";;

let validator_name = prompt_input "Validator name (nickname or organization)" non_empty "Name cannot be empty";;
print_endline "";;

let validator_website = prompt_input "Validator website (optional)" (fun _ -> true) "";;
print_endline "";;

let contact_email = prompt_input "Contact email" is_email "Invalid email format";;
print_endline "";;

let () = print_section "Contacts";;
print_endline "";;

let telegram_account = prompt_input "Telegram account" non_empty "Account cannot be empty";;
print_endline "";;

let discord_nickname = prompt_input "Discord nickname" non_empty "Nickname cannot be empty";;
print_endline "";;

let () = print_section "Server configuration";;
print_endline "";;

let server_location = prompt_input "Server location (City, Country)" is_location "Location must be in format 'City, Country'";;
print_endline "";;

let cluster = prompt_input "Cluster (will there be multiple servers? y/n)" is_yn "Please enter 'y' or 'n'";;
print_endline "";;

let uptime = prompt_input "Planned uptime (hours per day)" is_uptime "Enter a valid number (1-24)";;
print_endline "";;

let ip_type = prompt_input "IP address type (static/non-static)" is_ip_type "Enter 'static' or 'non-static'";;
print_endline "";;

let disk_size = prompt_input "Available disk space (MB)" is_number "Enter a valid number";;
print_endline "";;

let () = print_section "System information collection";;

let get_os_info () =
print_info "Getting OS information";
let info = get_command_output "uname -a" in
print_success "OS information collected successfully.";
info

let get_cpu_info () =
 print_info "Extracting CPU features and capabilities";
 let cpu_info = [
   ("brand", (if os_type = "macOS" then
               get_command_output "sysctl -n machdep.cpu.brand_string"
             else
               get_command_output "cat /proc/cpuinfo | grep 'model name' | head -n 1 | cut -d ':' -f2"));
   ("cores", (if os_type = "macOS" then
               get_command_output "sysctl -n hw.ncpu"
             else
               get_command_output "nproc"));
   ("features", (if os_type = "macOS" then
                  get_command_output "sysctl -a | grep machdep.cpu.features"
                else
                  get_command_output "lscpu | grep Flags | cut -d ':' -f2"));
   ("speed_MHz", (try
                   if os_type = "macOS" then
                     let speed = get_command_output "sysctl -n hw.cpufrequency" in
                     string_of_int (int_of_string speed / 1000000) ^ " MHz"
                   else
                     get_command_output "lscpu | grep 'MHz' | awk '{print $3}'"
                 with _ -> "N/A"))
 ] in
 print_success "CPU information and capabilities collected successfully.";
 cpu_info

let get_memory_info () =
print_info "Collecting memory information";
let mem_info = [
  ("total_memory", (try
                     if os_type = "macOS" then
                       let size = get_command_output "sysctl -n hw.memsize" in
                       string_of_int (int_of_string size / (1024 * 1024 * 1024)) ^ " GB"
                     else
                       let size = get_command_output "cat /proc/meminfo | grep MemTotal | awk '{print $2}'" in
                       string_of_int (int_of_string size / 1024) ^ " MB"
                   with _ -> "N/A"));
  ("type", (if os_type = "macOS" then
             (* safe call!!! *)
             get_command_output "system_profiler SPMemoryDataType | grep 'Type:' | head -n 1 | awk '{print $2}'"
           else
             get_command_output "dmidecode -t memory | grep Type | head -n 1 | awk '{print $2}'"))
] in
print_success "Memory information collected successfully.";
mem_info

let get_ip_address () =
print_info "Getting local IP address";
let ip = if os_type = "macOS" then
           get_command_output "ipconfig getifaddr en0"
         else
           get_command_output "hostname -I" in
print_success "Local IP collected successfully.";
ip

let get_external_ip () =
print_info "Getting external IP address";
let ip = get_command_output "curl -s ifconfig.me" in (* in production use our server for incoming connections, even if it is ipv6 *)
print_success "External IP collected successfully.";
ip

let os_info = get_os_info ()
let cpu_info = get_cpu_info ()
let mem_info = get_memory_info ()
let ltw_ip = get_ip_address ()
let ext_ip = get_external_ip ()

let () =
print_section "Creating configuration";
print_info "Preparing configuration data";
let config = `Assoc [
  ("validator", `Assoc [
    ("name", `String validator_name);
    ("website", `String validator_website);
    ("contact_email", `String contact_email);
    ("telegram_account", `String telegram_account);
    ("discord_nickname", `String discord_nickname);
    ("server_location", `String server_location);
    ("cluster", `String cluster); (* in the next version take config 5-31 for a separate cluster and allocate a segment for all machines! *)
    ("uptime", `String uptime);
    ("ip_type", `String ip_type);
    ("disk_size", `String disk_size)
  ]);
  ("system_info", `Assoc ([
    ("os_type", `String os_type);
    ("os", `String os_info);
    ("ltw_ip", `String ltw_ip);
    ("external_ip", `String ext_ip)
  ] @ List.map (fun (k, v) -> (k, `String v)) cpu_info
    @ List.map (fun (k, v) -> (k, `String v)) mem_info))
] in

print_info "Registering server in the Octra Network";
let json_str = Yojson.Basic.pretty_to_string config in
let uri = Uri.of_string "http://161.35.168.80:9000" in (* close the bootstrap gate after all participants have registered!!!!! *)

try
  (* only for a closed group of testers who have been authorized!!! *)
  let response = Client.post ~body:(Cohttp_lwt.Body.of_string json_str) uri |> Lwt_main.run in
  let body_str = Cohttp_lwt.Body.to_string (snd response) |> Lwt_main.run in
  let status = Cohttp.Response.status (fst response) in
  
  if status = `OK then (
    let res_json = Yojson.Basic.from_string body_str in
    let hash_id = res_json |> Util.member "hash" |> Util.to_string in
    let filename = hash_id ^ "_config.json" in (* ask lmd about what format will be during reset? *)
    let oc = open_out filename in
    output_string oc json_str;
    close_out oc;
    
    print_endline "";
    print_endline (success_box "Configuration successfully completed.");
    print_endline (green "Configuration details:");
    print_endline (cyan ("• Hash ID: " ^ bold hash_id));
    print_endline (cyan ("• File: " ^ bold filename));
    print_endline (dim "Your configuration has been saved locally and the authorization actor has registered this account in the network");
    print_header "Setup Complete"
  ) else (
    print_error ("Server responded with error: " ^ body_str);
    print_warning "Please check your configuration and try again";
    print_header "Setup failed"
  )
with e -> 
  print_error ("Failed to communicate with server: " ^ Printexc.to_string e);
  print_warning "Please check your internet connection and try again";
  print_header "Setup failed"