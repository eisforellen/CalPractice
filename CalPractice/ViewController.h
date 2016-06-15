//
//  ViewController.h
//  CalPractice
//
//  Created by Ellen Mey on 6/15/16.
//  Copyright © 2016 Ellen Mey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSCalendar.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLCalendar.h"

@interface ViewController : UIViewController <FSCalendarDataSource, FSCalendarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) GTLServiceCalendar *service;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, strong) NSMutableArray *eventsOnSelectedDate;


- (void)filterEventsByDate:(NSDate *)selectedDate;

@end

