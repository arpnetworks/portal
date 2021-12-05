# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Account.create({
  login: 'admin',
  password: 'arprocks',
  password_confirmation: 'arprocks',
  email: 'admin@example.com'
})

Account.create({
  login: 'chris',
  password: 'KeeH4Raavi',
  password_confirmation: 'KeeH4Raavi',
  email: 'chris@example.com'
})

Account.create({
  login: 'joe',
  password: 'ahB9Vood8a',
  password_confirmation: 'ahB9Vood8a',
  email: 'joe@example.com'
})

Account.create({
  login: 'kyle',
  password: 'ay3Thoh1ig',
  password_confirmation: 'ay3Thoh1ig',
  email: 'kyle@example.com'
})

location = {}
location['lax'] = Location.create(name: 'Los Angeles', code: 'lax')
location['fra'] = Location.create(name: 'Frankfurt',   code: 'fra')

Vlan.create(vlan: 1, label: 'Native VLAN', location: location['lax'])
Vlan.create(vlan: 1, label: 'Native VLAN', location: location['fra'])
