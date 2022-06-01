"""
ok, this app is kinda doing two things:
- it serves well-known requests at well-known endpoints
- it looks for those well-known requests and returns responses based on them
"""
from fastapi import FastAPI, Response, status
import requests
from cfenv import AppEnv

app_env = AppEnv()

HOSTNAME = app_env.uris[0]

HSTS = "strict-transport-security"
FRAME_OPTIONS = "x-frame-options"
CONTENT_TYPE_OPTIONS = "x-content-type-options"
XSS_PROTECTION = "x-xss-protection"
CONTENT_TYPE = "content-type"

DEFAULTS = {
    HSTS: "max-age=31536000",
    FRAME_OPTIONS: "DENY",
    CONTENT_TYPE_OPTIONS: "nosniff",
    XSS_PROTECTION: "1; mode=block",
    CONTENT_TYPE: "text/plain; charset=utf-8",
}
OVERRIDDEN = {name: f"{default}; semaphore" for name, default in DEFAULTS.items()}


app = FastAPI()


@app.get("/test")
def read_root():
    return "Success"


@app.get("/test-defaults")
def get_test_custom_hsts(response: Response):
    api_endpoint = f"https://{HOSTNAME}/test"
    r = requests.get(api_endpoint)
    errors = dict()
    for name, expected in DEFAULTS.items():
        if r.headers[name] != expected:
            errors[name] = dict(expected=expected, actual=r.headers[name])
    if errors:
        response.status_code = status.HTTP_500_CREATED
        return errors
    return "Success"


@app.get("/custom-headers-semaphores")
def get_custom_headers_semaphores(response: Response):
    for name, expected in OVERRIDDEN.items():
        response.headers[name] = expected
    return "Success"


@app.get("/test-headers-semaphores")
def get_test_custom_hsts(response: Response):
    api_endpoint = f"https://{HOSTNAME}/custom-headers-semaphores"
    r = requests.get(api_endpoint)
    errors = dict()
    for name, expected in OVERRIDDEN.items():
        if r.headers[name] != expected:
            errors[name] = dict(expected=expected, actual=r.headers[name])
    if errors:
        response.status_code = status.HTTP_500_CREATED
        return errors
    return "Success"


@app.get("/frame-options-allowall")
def get_frame_options_allowall(response: Response):
    response.headers[FRAME_OPTIONS] = "ALLOWALL"
    return "Success"


@app.get("/test-frame-options-allowall")
def get_test_custom_hsts(response: Response):
    """
    secureproxy maps 'ALLOWALL' to empty string in frame options
    which means the header should not be set
    """
    api_endpoint = f"https://{HOSTNAME}/frame-options-allowall"
    r = requests.get(api_endpoint)
    if FRAME_OPTIONS in r.headers:
        response.status_code = status.HTTP_500_CREATED
        return dict(expected="not-the-default", actual=r.headers[FRAME_OPTIONS])
    return "Success"


@app.get("/frame-options-allowall")
def get_frame_options_allowall(response: Response):
    response.headers[FRAME_OPTIONS] = "ALLOWALL"
    return "Success"


@app.get("/test-frame-options-allowall")
def get_test_custom_hsts(response: Response):
    """
    secureproxy maps 'ALLOWALL' to empty string in frame options
    which means the header should not be set
    """
    api_endpoint = f"https://{HOSTNAME}/frame-options-allowall"
    r = requests.get(api_endpoint)
    if FRAME_OPTIONS in r.headers:
        response.status_code = status.HTTP_500_CREATED
        return dict(expected="not-the-default", actual=r.headers[FRAME_OPTIONS])
    return "Success"



