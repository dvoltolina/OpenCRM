"""Shared exceptions for routing providers."""


class ProviderUnavailableError(Exception):
    """Raised when a routing provider cannot fulfill the request."""


class ProviderConfigurationError(ProviderUnavailableError):
    """Raised when provider configuration (keys/URLs) is invalid or missing."""
