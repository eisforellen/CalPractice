//
//  ViewController.m
//  CalPractice
//
//  Created by Ellen Mey on 6/15/16.
//  Copyright © 2016 Ellen Mey. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@property (weak, nonatomic) FSCalendar *calendar;
@property (strong, nonatomic) IBOutlet UITableView *eventTableView;


@end

@implementation ViewController

static NSString *const kKeychainItemName = @"Google Calendar API";
static NSString *const kClientID = @"CLIENT_ID";

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Initialize the Google Calendar API service & load existing credentials from the keychain if available.
    self.service = [[GTLServiceCalendar alloc] init];
    self.service.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientID
                                                      clientSecret:nil];
    

}

// When the view appears, ensure that the Google Calendar API service is authorized, and perform API calls.
- (void)viewDidAppear:(BOOL)animated {
    if (!self.service.authorizer.canAuthorize) {
        // Not yet authorized, request authorization by pushing the login UI onto the UI stack.
        [self presentViewController:[self createAuthController] animated:YES completion:nil];
        
    } else {
        [self fetchEvents];
    }
}

// Construct a query and get a list of upcoming events from the user calendar. Display the
// start dates and event summaries in the UITextView.
- (void)fetchEvents {
    GTLQueryCalendar *query = [GTLQueryCalendar queryForEventsListWithCalendarId:@"shrjhb45hjju0on9bh94mqi2c8@group.calendar.google.com"];
    query.maxResults = 10;
    query.timeMin = [GTLDateTime dateTimeWithDate:[NSDate date]
                                         timeZone:[NSTimeZone localTimeZone]];;
    query.singleEvents = YES;
    query.orderBy = kGTLCalendarOrderByStartTime;
    
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(addEventsWithTicket:finishedWithObject:error:)];
}

- (void)addEventsWithTicket:(GTLServiceTicket *)ticket finishedWithObject:(GTLCalendarEvents *)calendarEvents error:(NSError *)error {
    if (error == nil) {
        _events = [[NSMutableArray alloc] init];
        if ([calendarEvents.items count] > 0) {
            
            for (GTLCalendarEvent *event in calendarEvents) {
                if (event.start.dateTime) {
                    [_events addObject:event];
                }
            }
        } else {
            NSLog(@"No events");
        }
    } else {
        [self showAlert:@"Error" message:error.localizedDescription];
    }
    NSLog(@"Events array: %@", _events.description);
    [_eventTableView reloadData];
}

// Creates the auth controller for authorizing access to Google Calendar API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeCalendarReadonly, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc]
                      initWithScope:[scopes componentsJoinedByString:@" "]
                      clientID:kClientID
                      clientSecret:nil
                      keychainItemName:kKeychainItemName
                      delegate:self
                      finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Handle completion of the authorization process, and update the Google Calendar API
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
    }
    else {
        self.service.authorizer = authResult;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_eventsOnSelectedDate count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"eventCell"];
        
    }
    NSLog(@"Checking eventsOnSelectedDate in cell initialization: \n%@", _eventsOnSelectedDate.description);
    GTLCalendarEvent *eventInCell = [_eventsOnSelectedDate objectAtIndex:indexPath.row];
    cell.textLabel.text = eventInCell.summary;
    return cell;
}

- (void)filterEventsByDate:(NSDate *)selectedDate {
    _eventsOnSelectedDate = [[NSMutableArray alloc]init];
    NSMutableArray *copyOfEvents = [_events mutableCopy];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *selectedDateString = [dateFormatter stringFromDate:selectedDate];
    for (GTLCalendarEvent *event in copyOfEvents) {
        
        
        GTLCalendarEventDateTime *eventDate = event.start;
        GTLDateTime *gtlDateTimeInstance = eventDate.dateTime;
        NSString *dateToCompareWithSelectedDate = [dateFormatter stringFromDate:gtlDateTimeInstance.date];

        if ([dateToCompareWithSelectedDate isEqualToString:selectedDateString]) {
            [_eventsOnSelectedDate addObject:event];
            NSLog(@"eventsOnSelectedDate: %@", _eventsOnSelectedDate.description);
            NSLog(@"Event added to eventsOnSelectedDate");
            [_eventTableView reloadData];
        } else if (![dateToCompareWithSelectedDate isEqualToString:selectedDateString]) {
            [_eventsOnSelectedDate removeObject:event];
            NSLog(@"eventsOnSelectedDate: %@", _eventsOnSelectedDate.description);
            NSLog(@"Event removed from eventsOnSelectedDate");
            [_eventTableView reloadData];
        }
    }
    NSLog(@"Checking scope by printing eventsOnSelectedDate array: \n%@", _eventsOnSelectedDate.description);
}

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date
{
    
    NSLog(@"did select date %@",[calendar stringFromDate:date format:@"yyyy/MM/dd"]);
    NSLog(@"selected date: %@", date);
    [self filterEventsByDate:date];
}

//- (void)calendar:(FSCalendar *)calendar boundingRectWillChange:(CGRect)bounds animated:(BOOL)animated
//{
//    calendar.frame = (CGRect){calendar.frame.origin,bounds.size};
//}


@end
