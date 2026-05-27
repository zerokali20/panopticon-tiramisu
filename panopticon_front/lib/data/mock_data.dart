/// Static mock data for the Panopticon UI prototype.
/// Port of the inline data arrays from the React App.tsx.
library;

class CallRecord {
  final String name;
  final String number;
  final String risk; // 'high' | 'med' | 'safe'
  final int confidence;
  final String time;
  final String date;
  final String duration;
  final String? sub; // short summary for recent calls list

  const CallRecord({
    required this.name,
    required this.number,
    required this.risk,
    required this.confidence,
    required this.time,
    required this.date,
    required this.duration,
    this.sub,
  });
}

const List<CallRecord> recentCalls = [
  CallRecord(
    name: 'Wells Fargo Fraud Dept.',
    number: '+1 (415) 555-0117',
    risk: 'high',
    confidence: 98,
    time: '2:14 PM',
    date: 'Today',
    duration: '47s',
    sub: 'Flagged · Identity not verified',
  ),
  CallRecord(
    name: 'Mom',
    number: '+1 (650) 555-0188',
    risk: 'safe',
    confidence: 2,
    time: 'Yesterday',
    date: 'Yesterday',
    duration: '12m 04s',
    sub: '12 min · Local network',
  ),
  CallRecord(
    name: 'HMRC Tax Refund',
    number: '+44 20 7946 0958',
    risk: 'high',
    confidence: 91,
    time: 'Yesterday',
    date: 'Yesterday',
    duration: '1m 38s',
    sub: 'Flagged · Urgency pattern',
  ),
  CallRecord(
    name: 'Auto Warranty',
    number: '+1 (888) 555-0199',
    risk: 'med',
    confidence: 76,
    time: 'Tue',
    date: 'Tue',
    duration: '8s',
    sub: 'Robocall pattern',
  ),
  CallRecord(
    name: 'Dr. Whitaker',
    number: '+1 (415) 555-0124',
    risk: 'safe',
    confidence: 4,
    time: 'Mon',
    date: 'Mon',
    duration: '5m 22s',
    sub: '5 min · Saved contact',
  ),
];

const List<CallRecord> allCalls = [
  CallRecord(
    name: 'Wells Fargo Fraud Dept.',
    number: '+1 (415) 555-0117',
    risk: 'high',
    confidence: 98,
    time: '2:14 PM',
    date: 'Today',
    duration: '47s',
  ),
  CallRecord(
    name: 'Unknown',
    number: '+1 (888) 555-0142',
    risk: 'high',
    confidence: 94,
    time: '11:02 AM',
    date: 'Today',
    duration: '1m 12s',
  ),
  CallRecord(
    name: 'Mom',
    number: '+1 (650) 555-0188',
    risk: 'safe',
    confidence: 2,
    time: '7:38 PM',
    date: 'Yesterday',
    duration: '12m 04s',
  ),
  CallRecord(
    name: 'HMRC Tax Refund',
    number: '+44 20 7946 0958',
    risk: 'high',
    confidence: 91,
    time: '3:21 PM',
    date: 'Yesterday',
    duration: '1m 38s',
  ),
  CallRecord(
    name: 'Auto Warranty',
    number: '+1 (888) 555-0199',
    risk: 'med',
    confidence: 76,
    time: '10:14 AM',
    date: 'Tue',
    duration: '8s',
  ),
  CallRecord(
    name: 'Dr. Whitaker',
    number: '+1 (415) 555-0124',
    risk: 'safe',
    confidence: 4,
    time: '9:02 AM',
    date: 'Mon',
    duration: '5m 22s',
  ),
  CallRecord(
    name: 'Unknown',
    number: '+1 (212) 555-0163',
    risk: 'med',
    confidence: 58,
    time: '4:45 PM',
    date: 'Sun',
    duration: '22s',
  ),
  CallRecord(
    name: 'Amazon Delivery',
    number: '+1 (800) 555-0177',
    risk: 'high',
    confidence: 89,
    time: '2:11 PM',
    date: 'Sun',
    duration: '33s',
  ),
];
