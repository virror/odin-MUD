package main

import "core:fmt"
import "core:net"
import "core:thread"
import "core:strings"

send_msg2 :: proc(sock: i64, msg: string) {
	send_msg((net.TCP_Socket(sock)), msg)
}

send_msg :: proc(sock: net.TCP_Socket, msg: string) {
	_, err_send := net.send_tcp(sock, transmute([]u8)msg)
	if err_send != nil {
		fmt.println("Failed to send data")
	}
}

handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [256]u8

	send_msg(sock, "Welcome to the MUD! Please enter your username:")
	players[i64(sock)] = player_create()

	for {
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		player := &players[i64(sock)]
		
		if err_recv != nil {
			fmt.println(err_recv)
			player_leave(player, i64(sock))
			net.close(sock)
			return
		}
		input := string(buffer[:bytes_recv])

		switch player.status {
		case Player_status.Username:
			player.name = strings.clone(input)
			player_load(player)
			send_msg(sock, "Enter password:")
			player.socket = i64(sock)
			player.status = Player_status.Password
		case Player_status.Password:
			player.status = Player_status.Playing
			msg := rooms_description(player.current_room, player)
			send_msg(sock, msg)
			delete(msg)
			rooms[player.current_room].players[player.name] = player
		case Player_status.Playing:
			received := buffer[:bytes_recv]
			input_handle(sock, received)
		case Player_status.Quitting:
			if input == "yes" {
				send_msg(sock, "Goodbye!")
				player_leave(player, i64(sock))
				net.close(sock)
				return
			} else if input == "no" {
				send_msg(sock, "Welcome back!")
				player.status = Player_status.Playing
			} else {
				send_msg(sock, "Invalid input. Do you want to quit? (yes/no)")
			}
		}
	}
	net.close(sock)
}

tcp_mud_server :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = port,
	}
	sock, err := net.listen_tcp(endpoint)
	if err != nil {
		fmt.println("Failed to listen on TCP")
		return
	}
	fmt.printfln("Listening on TCP: %s", net.endpoint_to_string(endpoint))
	for {
		cli, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			fmt.println("Failed to accept TCP connection")
			continue
		}
		thread.create_and_start_with_poly_data(cli, handle_msg)
	}
	net.close(sock)
	fmt.println("Closed socket")
}

main :: proc() {
	input_init()
	rooms_init()
    tcp_mud_server("127.0.0.1", 8080)
}