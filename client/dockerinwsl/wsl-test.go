package DockerInWsl

import (
	"fmt"
	"net"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

func printfOk(format string, a ...any) (int, error) {
	return fmt.Printf(fmt.Sprintf("%s %s\n", green("[OK  ]"), format), a...)
}

func printfFail(format string, a ...any) (int, error) {
	return fmt.Printf(fmt.Sprintf("%s %s\n", red("[FAIL]"), format), a...)
}

func checkCommandInPath(command string) bool {
	path, err := exec.LookPath(command)
	if err == nil && path != "" {
		printfOk("Command '%s' is in path", command)
		return true
	}
	printfFail("Command '%s' is NOT in path", command)
	return false
}

func checkExecOutput(pattern string, name string, arg ...string) bool {
	cmd := exec.Command(name, arg...)

	env := os.Environ()
	for _, v := range env {
		fmt.Printf("%s\n", v)
		if strings.HasPrefix(v, "DOCKER") {
			fmt.Printf("%s\n", v)
		}
	}
	cmd.Env = env
	out, err := cmd.CombinedOutput()
	fmt.Printf("%s\n%s\n", err, out)
	if err != nil {
		printfFail("Executing '%s %s' failed with '%s'", name, arg, err)
		return false
	}

	// senetation because of pseudo-utf16 output of wsl-cli
	outClear := make([]byte, len(out))
	p := 0
	for _, b := range out {
		if b != 0 {
			outClear[p] = byte(b)
			p++
		}
	}
	text := string(outClear)

	m, err := regexp.MatchString(pattern, text)
	if err != nil {
		printfFail("Pattern '%s' failed on output of '%s %s' with '%s'", pattern, name, arg, err)
		return false
	}

	if !m {
		printfFail("'%s %s' does not contain pattern '%s'", name, arg, pattern)
		return false
	}
	printfOk("Command '%s %s' contains '%s'", name, arg, pattern)
	return true
}

func checkTcpPort(host string, port int16) bool {
	timeout := time.Second * 5
	hostport := net.JoinHostPort(host, strconv.Itoa(int(port)))
	conn, err := net.DialTimeout("tcp", hostport, timeout)
	if err == nil && conn != nil {
		defer conn.Close()
		printfOk("Connected to '%s'", hostport)
		return true
	}
	fmt.Printf("Unable to connect to '%s' ('%s')", hostport, err)
	return false
}

func (WslContext) Test() error {
	var failed_tests int = 0
	r := func(r bool) {
		if !r {
			failed_tests++
		}
	}

	r(checkCommandInPath("wsl"))
	r(checkCommandInPath("docker"))
	r(checkCommandInPath("docker-wsl"))

	r(checkExecOutput("dockerinwsl", "wsl", "-l"))

	r(checkTcpPort("localhost", 2375))
	r(checkTcpPort("127.0.0.1", 2375))
	r(checkTcpPort("::1", 2375))

	// DNS Check from WSL
	r(checkExecOutput("Address: 1.1.1.1", "wsl", "-d", "clf_dockerinwsl", "nslookup", "one.one.one.one"))
	r(checkExecOutput("Address: 192.168.67.2", "wsl", "-d", "clf_dockerinwsl", "nslookup", "host.docker.internal"))
	r(checkExecOutput("Address: 192.168.67.1", "wsl", "-d", "clf_dockerinwsl", "nslookup", "gateway.docker.internal"))
	r(checkExecOutput("Address: 192.168.67.2", "wsl", "-d", "clf_dockerinwsl", "nslookup", "host.internal"))
	r(checkExecOutput("Address: 192.168.67.3", "wsl", "-d", "clf_dockerinwsl", "nslookup", "wsl.internal"))

	// DNS Check from Container
	r(checkExecOutput("Address: 1.1.1.1", "docker", "run", "--rm", "alpine", "nslookup", "one.one.one.one"))
	r(checkExecOutput("Address: 192.168.67.2", "docker", "run", "--rm", "alpine", "nslookup", "host.docker.internal"))
	r(checkExecOutput("Address: 192.168.67.1", "docker", "run", "--rm", "alpine", "nslookup", "gateway.docker.internal"))
	r(checkExecOutput("Address: 192.168.67.2", "docker", "run", "--rm", "alpine", "nslookup", "host.internal"))
	r(checkExecOutput("Address: 192.168.67.3", "docker", "run", "--rm", "alpine", "nslookup", "wsl.internal"))

	if failed_tests > 0 {
		fmt.Printf("\n%d TESTS FAILED!\n", failed_tests)
	} else {
		fmt.Printf("\nall tests successfull!\n")
	}

	return nil
}
