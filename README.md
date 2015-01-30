## House Staff Directory

A staff directory for the House of Representatives, using data culled from the House' [quarterly disbursement records](http://disbursements.house.gov/).

The House publishes each quarter's data by the end of the following quarter, so the records will generally be 3-6 months out of date.

### Setup

Depends on Ruby 1.8.7 - not tested on anything higher. This needs to be updated.

Install dependencies with bundler:

```bash
bundle install
```

Copy config.ru:

```bash
cp config.ru.example config.ru
```

Copy config/config.yml.example:

```cp config/config.yml.example config/config.yml ```

Run with unicorn:

```bash
bundle exec unicorn
```

### Loading new staff records

It's an old, blunt, violent process.

1. Get the CSVs generated from the [sunlightlabs/disbursements](https://github.com/sunlightlabs/disbursements) process.

2. Put them into the `data/` directory and run:

```bash
rake load:all
```

3. Wait for an hour or more as the data is blown away and reloaded from scratch. It's not very efficient, and the website will show incomplete data for that time.

4. Update the 'as of' date displayed on the home page in views/index.erb to the last day of the quarter processed.


### data/ expectations

The `data/` directory expects four CSV files:

* `staffers.csv`: Unique staffer names as they appear in the original disbursement data, and any standardizations or corrections to those titles.
* `titles.csv`: Unique titles as they appear in the original disbursement data, and any standardizations or corrections to those titles.
* `offices.csv`: Unique office names as they appear in the original disbursement data, and any standardizations or corrections to those titles. Expanded details for each office (committee ID, building, room, telephone number) are added by hand.
* `positions.csv`: The "join table" that links staffer names, title names, and office names together as a "position" for each quarter.

### Why not the Senate?

The [Senate's expenditure data](http://www.senate.gov/legislative/common/generic/report_secsen.htm) is published every 6 months, can be quite out of date, and is much more difficult to parse than the House's.

Our [parser for the House is here](https://github.com/sunlightlabs/disbursements). The Senate parser is still experimental, but data can be found [here](http://sunlightfoundation.com/blog/2014/08/05/now-its-easier-to-account-for-how-the-senate-spends-your-money/).

### License

Currently [GPLv3](LICENSE).