""" Module defining Flask App and Aws Lambda entry point"""
from typing import Any

from apig_wsgi import make_lambda_handler
from flask import Flask

from . import frontend


def create_app() -> Flask:
    """ Create and configure a simple Flask app"""
    app = Flask(__name__)
    app.register_blueprint(frontend.v1)

    # no version blueprint for /ping, register it here
    @app.route("/ping", methods=["GET"])
    def ping():
        return "", 204
    return app


apig_wsgi_handler = make_lambda_handler(create_app(), binary_support=True)


def lambda_handler(event: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    """ Aws Lambda Entry point"""
    response = apig_wsgi_handler(event, context)  # pragma: no cover
    return response                               # pragma: no cover
