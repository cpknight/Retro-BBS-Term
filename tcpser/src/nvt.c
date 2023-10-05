#include <string.h>

#include "debug.h"
#include "ip.h"
#include "modem_core.h"

#include "nvt.h"

void nvt_init_config(nvt_vars *vars) {
  int i; 

  vars->binary_xmit = FALSE;
  vars->binary_recv = FALSE;
  for (i = 0; i < 256; i++)
    vars->term[i] = 0;
}

unsigned char get_nvt_cmd_response(unsigned char action, unsigned char type) {
  unsigned char rc = 0;

  if(type == TRUE) {
    switch (action) {
      case NVT_DO:
        rc = NVT_WILL;
        break;
      case NVT_DONT:
        rc = NVT_WONT;
        break;
      case NVT_WILL:
        rc = NVT_DO;
        break;
      case NVT_WONT:
        rc = NVT_DONT;
        break;
    }
  } else {
    switch (action) {
      case NVT_DO:
      case NVT_DONT:
        rc = NVT_WONT;
        break;
      case NVT_WILL:
      case NVT_WONT:
        rc = NVT_DONT;
        break;
    }
  }
  return rc;
}

int parse_nvt_subcommand(dce_config *cfg, int fd, nvt_vars *vars, unsigned char *data, int len) {
  // overflow issue, again...
  nvt_option opt = data[2];
  unsigned char resp[100];
  unsigned char *response = resp + 3;
  int resp_len = 0;
  int response_len = 0;
  char tty_type[] = "VT100";
  int rc;
  char buf[50];
  int slen = 0;

  for (rc = 2; rc < len - 1; rc++) {
    if (NVT_IAC == data[rc])
      if (NVT_SE == data[rc + 1]) {
        rc += 2;
        break;
      }
  }

  if (rc > 5 && (NVT_SB_SEND == data[3])) {
    switch(opt) {
      case NVT_OPT_TERMINAL_TYPE:
      case NVT_OPT_X_DISPLAY_LOCATION:  // should not have to have these
      case NVT_OPT_ENVIRON:             // but telnet seems to expect.
      case NVT_OPT_NEW_ENVIRON:         // them.
      case NVT_OPT_TERMINAL_SPEED:
        response[response_len++] = NVT_SB_IS;
        switch(opt) {
          case NVT_OPT_TERMINAL_TYPE:
            slen = strlen(tty_type);
            strncpy((char *)response + response_len, tty_type, slen);
            response_len += slen;
            break;
          case NVT_OPT_TERMINAL_SPEED:
            sprintf(buf, "%i,%i", cfg->port_speed, cfg->port_speed);
            slen = strlen(buf);
            strncpy((char *)response + response_len, buf, slen);
            response_len += slen;
            break;
          default:
            break;
        }
        break;
      default:
        break;
    }
  }

  if (response_len) {
    resp[resp_len++] = NVT_IAC;
    resp[resp_len++] = NVT_SB;
    resp[resp_len++] = opt;
    resp_len += response_len;
    resp[resp_len++] = NVT_IAC;
    resp[resp_len++] = NVT_SE;
    ip_write(fd, resp, resp_len);
  }
  return rc;
}

void get_action(char *txt, nvt_command action) {
  switch (action) {
  case NVT_WILL:
    strcpy(txt, "WILL");
    break;
  case NVT_WONT:
    strcpy(txt, "WONT");
    break;
  case NVT_DO:
    strcpy(txt, "DO");
    break;
  case NVT_DONT:
    strcpy(txt, "DONT");
    break;
  default:
    strcpy(txt, "UNKNOWN");
    break;
  }
}

int send_nvt_command(int fd, nvt_vars *vars, nvt_command action, nvt_option opt) {
  unsigned char cmd[3];
  char txt[20];

  get_action(txt, action);
  LOG(LOG_DEBUG, "Sending NVT command: %s %d", txt, opt);
  cmd[0] = NVT_IAC;
  cmd[1] = action;
  cmd[2] = opt;

  ip_write(fd, cmd, 3);
  vars->term[opt] = action;

  return 0;
}

int parse_nvt_command(dce_config *cfg, int fd, nvt_vars *vars, nvt_command action, nvt_option opt) {
  int accept = FALSE;
  char txt[20];
  int resp;

  get_action(txt, action);
  LOG(LOG_DEBUG, "Received NVT command: %s %d", txt, opt);
  switch (opt) {
    case NVT_OPT_TRANSMIT_BINARY :
      switch (action) {
        case NVT_DO:
          if(!dce_get_parity(cfg)) {
            LOG(LOG_INFO, "Enabling telnet binary xmit");
            vars->binary_xmit = TRUE;
            accept = TRUE;
          }
          break;
        case NVT_DONT:
          LOG(LOG_INFO, "Disabling telnet binary xmit");
          vars->binary_xmit = FALSE;
          accept = TRUE;
          break;
        case NVT_WILL:
          if(!dce_get_parity(cfg)) {
            LOG(LOG_INFO, "Enabling telnet binary recv");
            vars->binary_recv = TRUE;
            accept = TRUE;
          }
          break;
        case NVT_WONT:
          LOG(LOG_INFO, "Disabling telnet binary recv");
          vars->binary_recv = FALSE;
          accept = TRUE;
          break;
        default:
          break;
      }
      resp = get_nvt_cmd_response(action, accept);
      break;
    case NVT_OPT_NAWS:
    case NVT_OPT_TERMINAL_TYPE:
    case NVT_OPT_SUPPRESS_GO_AHEAD:
    case NVT_OPT_ECHO:
    case NVT_OPT_X_DISPLAY_LOCATION:  // should not have to have these
    case NVT_OPT_ENVIRON:             // but telnet seems to expect.
    case NVT_OPT_NEW_ENVIRON:         // them.
    case NVT_OPT_TERMINAL_SPEED:
      resp = get_nvt_cmd_response(action, TRUE);
      break;
    default:
      resp = get_nvt_cmd_response(action, FALSE);
      break;
  }
  send_nvt_command(fd, vars, resp, opt);
  return 0;
}
