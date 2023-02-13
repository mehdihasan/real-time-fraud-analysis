import psycopg2
from config import config
import time


def print_current_row(cursor: psycopg2._psycopg.cursor, first_name: str = "Rica") -> None:
    print(f"{first_name}'s current information")
    statement = "select * from CUSTOMERS where first_name = %s"
    cursor.execute(statement, [first_name])
    results = cursor.fetchall()
    for result in results:
        print(result)


def update_row(cursor: psycopg2._psycopg.cursor,
               connection: psycopg2._psycopg.connection,
               first_name: str = "Rica") -> None:
    statement = "update CUSTOMERS set avg_credit_spend = avg_credit_spend+1 where first_name = %s"
    print(f"increasing {first_name}'s average credit spend by $1")
    cursor.execute(statement, [first_name])
    connection.commit()


if __name__=="__main__":
    params = config()
    with psycopg2.connect(**params) as connection:

        cursor = connection.cursor()

        try:
            while True:
                print_current_row(cursor)
                update_row(cursor, connection)
                time.sleep(5)
        except KeyboardInterrupt:
            cursor.close()
            if connection is not None:
                connection.close()

            print("\nclosing")
