import os
import random
from datetime import datetime, timedelta

##################################################################################
# Script to generate random data that will be imported to MariaDB and Apache Kudu.
#
# The random_data_xxx.csv files were used to do the databases benchmarks.
##################################################################################


def random_data(preffix, n):
    """
    Generates n random elements. The element will be given preffix with i where i 
    values are from 0 to n - 1.
    
    :param preffix: the preffix
    :param n: the number of element to generate
    :return: the random data generated
    """
    return ['{}{}'.format(preffix, i) for i in range(0, n)]

# Number of tries to generate a key not already created
TRIES = 10
# Number of rows to generate
ROWS = 128000

page_names = random_data('page', 400000)
domains = random_data('domain', 200)
tlds = [
    'es', 'pt', 'it', 'gr', 'uk', 'us', 'mx', 'ma',
    'il', 'br', 'ab', 'ac', 'ad', 'at', 'zz', 'bb',
    'ax', 'aw'
]
FORMAT = '%Y-%m-%d'
base_date = datetime.strptime('2016-01-01', FORMAT)
tags = random_data('tag', 10000)

# Keys already generated used to not generate duplicated rows
keys_already_generated = set()
rows = []

# File where random data is stored
dir = os.path.dirname(__file__)
file_data = os.path.join(dir, 'random_data.csv')

for dummy_1 in range(0, ROWS):

    for dummy_2 in range(0, TRIES):

        page_name = random.choice(page_names)
        domain = random.choice(domains)
        # Range of 2 years of random dates
        date_stats = base_date + timedelta(days=random.randint(0, 365 * 2))
        tld = random.choice(tlds)

        key = "{}_{}_{}_{}".format(page_name, domain, tld, str(date_stats))
        if key in keys_already_generated:
            continue

        keys_already_generated.add(key)

        views = str(random.randint(1, 80000))
        visits = str(random.randint(1, 40000))
        average = str(random.randint(1, 100))
        bounce_rate = str(random.randint(1, 100))
        new_visitors = str(random.randint(1, 100))
        tag = random.choice(tags)

        # Create the row with | as separator
        row = "|".join([
            page_name, date_stats.strftime(FORMAT), domain, tld,
            views, visits, average, bounce_rate, new_visitors, tag
        ])

        # Append the row, after add new line to it.
        rows.append('{}\n'.format(row))

        break

    if len(keys_already_generated) % 10000 == 0:
        print("{}".format(len(keys_already_generated)))

print("")
print("")
print("{} rows generated".format(len(keys_already_generated)))

# Write the rows into the csv file
with open(file_data, 'w') as f:
    print("Writing file")
    f.writelines(rows)
    print("Done!")
