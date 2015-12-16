#!flask/bin/python
from flask import Flask, jsonify

app = Flask(__name__)

errors = [
    {
        'line':1,
        'column': 5,
        'error': 'Dude, I expected an exclamation point!'
    },
    {
        'line':10,
        'column': 10,
        'error': 'Dont use this word!!'
    }
]

@app.route('/getError', methods=['GET'])
def get_tasks():
    return 'Should be a exclamation point here'

if __name__ == '__main__':
    app.run(debug=True)
