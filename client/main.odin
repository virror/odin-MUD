package main

import "core:fmt"
import "core:net"
import "core:os"
import "core:thread"

handle_msg :: proc(sock: net.TCP_Socket) {
	buffer: [256]u8

	for {
		bytes_recv, err_recv := net.recv_tcp(sock, buffer[:])
		if err_recv != nil {
			fmt.println("Failed to receive data")
			break
		}
		input := string(buffer[:bytes_recv])
		fmt.println(input)
	}
	net.close(sock)
}

tcp_echo_client :: proc(ip: string, port: int) {
	local_addr, ok := net.parse_ip4_address(ip)
	if !ok {
		fmt.println("Failed to parse IP address")
		return
	}
	sock, err := net.dial_tcp_from_address_and_port(local_addr, port)
	if err != nil {
		fmt.println("Failed to connect to server")
		return
	}

	thread.create_and_start_with_poly_data(sock, handle_msg)

	buffer: [256]u8
	for {
		n, err_read := os.read(os.stdin, buffer[:])
		if err_read != nil {
			fmt.println("Failed to read data")
			break
		}
		if n == 0 || buffer[0] == '\n' || buffer[0] == '\r' {
			continue
		}
		data := buffer[:n - 2]
		_, err_send := net.send_tcp(sock, data)
		if err_send != nil {
			fmt.println("Failed to send data")
			break
		}
	}
	net.close(sock)
}

main :: proc() {
	tcp_echo_client("127.0.0.1", 8080)
}