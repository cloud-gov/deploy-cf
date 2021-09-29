from fastapi import FastAPI, Response, status
import requests

app = FastAPI()


@app.get("/test")
def read_root():
    return "Success"


@app.get("/test-external-networks")
def get_external_networks(response: Response):
    api_endpoint = "https://api.usaspending.gov/api/v2/references/toptier_agencies/?sort=budget_authority_amount&order=desc"

    try:
        api_response = requests.get(api_endpoint)
        response.content = "Success"
        return response
    except Exception as e:
        response.status_code = status.HTTP_500_CREATED
        return response

@app.get("/test-internal-networks")
def get_internal_networks(response: Response):
    try:
        response.content = "Success"
        return response
    except Exception as e:
        response.status_code = status.HTTP_500_CREATED
        return response
