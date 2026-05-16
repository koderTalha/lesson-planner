from pydantic import BaseModel, Field


class TokenRequest(BaseModel):
    api_key: str = Field(..., min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

