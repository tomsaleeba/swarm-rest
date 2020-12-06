This is a Flask server that can serve up a chart of cumulative user growth of
AusplotsR users over time. The result looks like:

![](./users-over-time.png)

# How to use it
At the time of writing, the ES server has no auth so it can't be exposed to the
public internet. That means you need to create an SSH tunnel and then connect
this tool to the tunnel port on your localhost. Alternatively, you could run it
on the machine that is running ES.

  1. create a virtual environment
      ```bash
      virtualenv -p python3 .venv
      . .venv/bin/activate
      ```
  1. install dependencies
      ```bash
      pip install -r requirements.txt
      ```
  1. start the server
      ```bash
      python main.py
      # OR, if you want to specify the ElasticSearch server
      ES_URL_PREFIX=http://localhost:30002 python main.py
      ```
  1. grab the address from the output from the previous command:
      ```
      ...
      * Running on http://0.0.0.0:30006/ (Press CTRL+C to quit)
      ...
      ```
  1. open that address ([`http://0.0.0.0:30006/`]()) in your browser
