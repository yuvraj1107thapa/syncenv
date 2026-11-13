package cron

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"syncenv/internal/logging"
)

func Install(executable string, interval int) error {
	if interval <= 0 {
		interval = 30 // default to 30 minutes
	}
	cronLine := fmt.Sprintf("*/%d * * * * %s --quiet sync >/dev/null 2>&1", interval, executable)
	existing := readCrontab()
	filtered := filterSyncEnv(existing)
	filtered = append(filtered, cronLine)
	if err := writeCrontab(filtered); err != nil {
		return err
	}
	logging.Log("SUCCESS", fmt.Sprintf("Installed cron job for %d-minute sync", interval))
	logging.Log("INFO", "Next sync will happen automatically")
	return nil
}

func Remove() error {
	existing := readCrontab()
	filtered := filterSyncEnv(existing)
	if len(filtered) == len(existing) {
		logging.Log("INFO", "No cron job found")
		return nil
	}
	if err := writeCrontab(filtered); err != nil {
		return err
	}
	logging.Log("SUCCESS", "Removed cron job")
	return nil
}

func Show() error {
	existing := readCrontab()
	filtered := filterSyncEnv(existing)
	if len(filtered) == len(existing) {
		logging.Log("INFO", "No cron job installed")
		fmt.Println("Run 'syncenv cron --install' to set up periodic sync")
		return nil
	}
	fmt.Println("Current cron job:")
	for _, line := range existing {
		if strings.Contains(line, "syncenv") {
			fmt.Println(line)
		}
	}
	return nil
}

func readCrontab() []string {
	cmd := exec.Command("crontab", "-l")
	output, err := cmd.Output()
	if err != nil {
		return []string{}
	}
	lines := strings.Split(strings.TrimSuffix(string(output), "\n"), "\n")
	if len(lines) == 1 && lines[0] == "" {
		return []string{}
	}
	return lines
}

func writeCrontab(lines []string) error {
	cmd := exec.Command("crontab", "-")
	input := bytes.NewBufferString(strings.Join(lines, "\n") + "\n")
	cmd.Stdin = input
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func filterSyncEnv(lines []string) []string {
	filtered := []string{}
	for _, line := range lines {
		if strings.Contains(line, "syncenv") {
			continue
		}
		filtered = append(filtered, line)
	}
	return filtered
}
