import boto3
from botocore.exceptions import BotoCoreError, ClientError

MODEL_ID = (
    "arn:aws:bedrock:us-east-1:939328548754:"
    "inference-profile/us.anthropic.claude-haiku-4-5-20251001-v1:0"
)


def main() -> None:
    client = boto3.client("bedrock-runtime", region_name="us-east-1")

    try:
        response = client.converse(
            modelId=MODEL_ID,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "text": (
                                "Hola. Responde únicamente: "
                                "Bedrock funciona desde Python."
                            )
                        }
                    ],
                }
            ],
            inferenceConfig={
                "maxTokens": 50,
                "temperature": 0,
            },
        )

        text = response["output"]["message"]["content"][0]["text"]
        print(text)

    except (ClientError, BotoCoreError) as error:
        print(f"Error al invocar Bedrock: {error}")
        raise


if __name__ == "__main__":
    main()
