from src.hello_world import hello_world

fake_json_endpoint = 'https://jsonplaceholder.typicode.com/posts/1'


def main(event=None, context=None):
    hello_world(event, context)


if __name__ == '__main__':
    main(None, None)