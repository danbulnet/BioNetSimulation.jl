import JSON

questionsjson = r"""
    {
        "questions_keys": {
            "test_question_1": {
                "type": "range",
                "attributes": {
                    "min": -1,
                    "max": 1
                },
                "question"=> "Przykładowe pytanie",
                "label": {
                    "min": "bardzo źle",
                    "max": "dobrze"
                }
            },
            "test_question_2": {
                "type": "range",
                "attributes": {
                    "min": -1,
                    "max": 1
                },
                "question"=> "Przykładowe pytanie 2",
                "label": {
                    "min": "bardzo źle",
                    "max": "dobrze"
                }
            },
        },
    }
"""

questions = JSON.json(questionsjson)