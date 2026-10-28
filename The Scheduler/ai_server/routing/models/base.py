"""Shared Pydantic config for routing models."""

from pydantic import BaseModel, ConfigDict


class RoutingBaseModel(BaseModel):
    """Base model with relaxed protected namespace to allow model_* fields."""

    model_config = ConfigDict(protected_namespaces=())
