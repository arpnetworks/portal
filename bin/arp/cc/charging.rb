# Author: Garry
# Date  : 01-14-2012
#
# Charge credit cards for all unpaid invoices

$REPORT = $ARGV[0]
$SHOW_SR = $ARGV[1]
$EMAIL_DN = $ARGV[2]
$ONLY_RECENTS = $ARGV[3]
$SUSPEND_MODE = $ARGV[4]

if $ARGV[0] == '--help'
  usage
  exit 1
end

$REPORT = false if $REPORT == "0"
$SHOW_SR = false if $SHOW_SR == "0"
$EMAIL_DN = false if $EMAIL_DN == "0"
$ONLY_RECENTS = false if $ONLY_RECENTS == "0"
$SUSPEND_MODE = false if $SUSPEND_MODE == "0"

# In days
$RECENT_CC_UPDATE_INTERVAL = 14

# Suspend mode forces report only
if $SUSPEND_MODE
  $REPORT = true
end

def usage
  puts "./script/runner charging.rb [report_only] [show_sales_receipts] [email_decline_notice] [only_recents] [suspend_mode]"
end

def unlock_cc
  puts ""
  puts "I need to unlock this account's credit card, paste private key:"

  key = ""
  next_ = ""
  loop do
    line1 = $stdin.gets
    line2 = $stdin.gets

    if line1 == "\n" && line2 == "\n"
      break
    end

    key += line1 + line2
  end

  puts ""
  puts "Passphrase?"
  pp = $stdin.gets.chomp

  unless CreditCard.unlock!(key, pp)
    fail "Failed to unlock credit card"
  end
end

def charge_invoices!
  total_unpaid = 0

  accounts_with_unpaid_invoices = []
  Invoice.unpaid.each do |invoice|
    if $ONLY_RECENTS
      cc = invoice.account.credit_card
      next if cc.nil?

      if (Time.now - cc.updated_at) > $RECENT_CC_UPDATE_INTERVAL*60*60*24
        next
      end
    end

    accounts_with_unpaid_invoices << invoice.account
  end

  accounts_with_unpaid_invoices.uniq!

  # Make sure nobody can make an online payment while we're doing our own
  File.open($PAYMENT_SYSTEM_DISABLED_LOCKFILE, "w") {}

  accounts_with_unpaid_invoices.each do |account|
    val1, val2 = account.charge_unpaid_invoices!($REPORT, $SHOW_SR, $EMAIL_DN, $SUSPEND_MODE)
    total_unpaid += val1.to_f
    @total_charged += val2.to_f
  end

  File.delete($PAYMENT_SYSTEM_DISABLED_LOCKFILE)

  if $REPORT
    puts "Total Unpaid Invoices: #{money(total_unpaid)}"
    puts "Total Customers with Unpaid Invoices: #{accounts_with_unpaid_invoices.size}"
  end
end

def main
  if !$REPORT
    unlock_cc
  end

  @total_charged = 0
  charge_invoices!

  puts "Total Charged: #{money(@total_charged)}" unless $REPORT
end

main
