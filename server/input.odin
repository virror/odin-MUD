package main

import "core:fmt"
import "core:net"
import "core:strings"

m: map[string]proc(string, ^Player) -> string

input_init :: proc() {
    m = make(map[string]proc(string, ^Player) -> string)
    m["quit"] = input_quit
	m["look"] = input_look
	m["north"] = input_north
    m["south"] = input_south
    m["east"] = input_east
    m["west"] = input_west
    m["say"] = input_say
}

input_handle :: proc(sock: net.TCP_Socket, data: []u8) {
    fmt.printfln("Received string: %s", string(data))
    command := strings.split(string(data), " ")[0]
    elem, ok := m[command]
    if(!ok) {
        send_msg(sock, "Invalid command")
        return
    }
    msg := elem(string(data), &players[i64(sock)])
    send_msg(sock, msg)
    //delete(msg)
}

input_quit :: proc(data: string, player: ^Player) -> string {
    player.status = Player_status.Quitting
    return "Do you want to quit? (yes/no)"
}

input_look :: proc(data: string, player: ^Player) -> string {
	return rooms[player.current_room].description
}

input_north :: proc(data: string, player: ^Player) -> string {
	return rooms_move(player, 0)
}

input_south :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 2)
}

input_east :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 1)
}

input_west :: proc(data: string, player: ^Player) -> string {
    return rooms_move(player, 3)
}

input_say :: proc(data: string, player: ^Player) -> string {
    msg, ok := strings.substring(data, 4, len(data))
    if !ok {
        return "Usage: say <message>"
    }
    for _, p in rooms[player.current_room].players {
        if p.socket != player.socket {
            send_msg2(p.socket, fmt.aprintf("%s says: %s", player.name, msg))
        }
    }
    return fmt.aprintf("You say: %s", msg)
}