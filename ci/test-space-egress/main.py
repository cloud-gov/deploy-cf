from fastapi import FastAPI, Response, status
import requests
import psycopg2
from cfenv import AppEnv


def test_db_connection():
    db = AppEnv().get_service(label="aws-rds")
    conn_string = db.credentials["uri"]
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    cur.execute("select count(1);")
    result = cur.fetchone()
    cur.close()
    conn.close()

    return result


app = FastAPI()


@app.get("/test")
def read_root():
    return "Success"


@app.get("/test-external-networks")
def get_external_networks(response: Response):
    api_endpoint = "https://api.usaspending.gov/api/v2/references/toptier_agencies/?sort=budget_authority_amount&order=desc"

    try:
        api_response = requests.get(api_endpoint)

        if api_response.status_code != 200:
            raise Exception()

        return "Success"
    except Exception as e:
        response.status_code = status.HTTP_500_CREATED
        return response


@app.get("/test-internal-networks")
def get_internal_networks(response: Response):
    try:
        result = test_db_connection()

        if result[0] != 1:
            raise Exception()

        return "Success"
    except Exception as e:
        response.status_code = status.HTTP_500_CREATED
        return response
