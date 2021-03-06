//
//  MainViewController.m
//  GeoTappy
//
//  Created by Dylan Marriott on 11/10/14.
//  Copyright (c) 2014 Dylan Marriott. All rights reserved.
//

#import "MainViewController.h"
#import "User.h"
#import "UserDefaults.h"
#import <CoreLocation/CoreLocation.h>
#import "Group.h"
#import "GroupEditViewController.h"
#import "SplashViewController.h"
#import "CustomCell.h"
#import "FavouriteListener.h"
#import "PreferencesView.h"
#import <KLCPopup/KLCPopup.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <DragAndDropTableView/DragAndDropTableView.h>
#import "Friend.h"
#import "LocationPostmaster.h"

static const NSUInteger MAX_FAVS = 5;

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, FavouriteListener, PreferencesViewDelegate, MFMailComposeViewControllerDelegate, DragAndDropTableViewDataSource, DragAndDropTableViewDelegate>

@end

@implementation MainViewController {
    CLLocationManager* _locationManager;
    User* _user;
    DragAndDropTableView* _tableView;
    UIImageView* _profileImageView;
    UIImageView* _coverImageView;
    KLCPopup* _popup;
    UIRefreshControl* _refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _user = [UserDefaults instance].currentUser;
    [_user addFavouriteListener:self];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    _coverImageView = [[UIImageView alloc] initWithImage:_user.coverImage];
    _coverImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 150);
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_coverImageView];
    
    UIImageView* superbg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"superbg"]];
    superbg.frame = CGRectMake(0, 0, self.view.frame.size.width, 150);
    superbg.alpha = 0.5;
    [self.view addSubview:superbg];
    
    _profileImageView = [[UIImageView alloc] initWithImage:_user.profileImage];
    _profileImageView.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 34, 70, 70);
    _profileImageView.clipsToBounds = YES;
    _profileImageView.layer.cornerRadius = 35;
    _profileImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    _profileImageView.layer.borderWidth = 4;
    _profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_profileImageView setUserInteractionEnabled:YES];
    [_profileImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionPreferences:)]];
    [self.view addSubview:_profileImageView];
    
    UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _profileImageView.frame.origin.y + _profileImageView.frame.size.height + 12, self.view.frame.size.width, 20)];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    nameLabel.layer.shadowRadius = 1;
    nameLabel.layer.shadowOffset = CGSizeMake(0, 0);
    nameLabel.layer.shadowOpacity = 0.5;
    nameLabel.layer.masksToBounds = NO;
    nameLabel.clipsToBounds = NO;
    nameLabel.text = _user.name;
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:nameLabel];
    
    
    UIButton* editButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 110, 35, 35)];
    [editButton setImage:[[UIImage imageNamed:@"edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    editButton.tintColor = [UIColor whiteColor];
    editButton.layer.shadowColor = [UIColor blackColor].CGColor;
    editButton.layer.shadowRadius = 1;
    editButton.layer.shadowOffset = CGSizeMake(0, 0);
    editButton.layer.shadowOpacity = 0.5;
    editButton.layer.masksToBounds = NO;
    [editButton addTarget:self action:@selector(actionEdit:) forControlEvents:UIControlEventTouchUpInside];
    //[self.view addSubview:editButton];
    
    
    UIButton* addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 25 - 10, 115, 25, 25)];
    [addButton setImage:[[UIImage imageNamed:@"add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    addButton.tintColor = [UIColor whiteColor];
    addButton.layer.shadowColor = [UIColor blackColor].CGColor;
    addButton.layer.shadowRadius = 1;
    addButton.layer.shadowOffset = CGSizeMake(0, 0);
    addButton.layer.shadowOpacity = 0.5;
    addButton.layer.masksToBounds = NO;
    [addButton addTarget:self action:@selector(actionAdd:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addButton];
    
    
    _tableView = [[DragAndDropTableView alloc] initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height - 150) style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];
    
    // this is just to get the permission here in the app
    // has to be an instance var, otherwise it will get released, an the alert view disappears
    // a reason to <3 apple
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager requestWhenInUseAuthorization];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    
    if (![UserDefaults instance].pushToken) {
        UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)refresh:(id)sender {
    [_user refreshWithCompletion:^() {
        [_refreshControl endRefreshing];
    }];
}

- (void)actionEdit:(id)sender {
    [_tableView setEditing:!_tableView.editing animated:YES];
}

- (void)actionAdd:(id)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"New Group" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField* textField) {
        textField.placeholder = @"Enter a group name";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertTextFieldDidChange:) name:UITextFieldTextDidChangeNotification object:textField];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                                   [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
                                   Group* group = [[Group alloc] init];
                                   UITextField* firstField = alertController.textFields.firstObject;
                                   group.name = firstField.text;
                                   if (_user.selectedFavourites.count < MAX_FAVS) {
                                       [_user.selectedFavourites addObject:group];
                                   } else {
                                       [_user.unselectedFavourites addObject:group];
                                   }
                                   [_user save];
                                   GroupEditViewController* vc = [[GroupEditViewController alloc] initWithGroup:group user:_user];
                                   [self.navigationController pushViewController:vc animated:YES];
                               }];
    okAction.enabled = NO;
    [alertController addAction:okAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)alertTextFieldDidChange:(NSNotification *)notification {
    UIAlertController* alertController = (UIAlertController *)self.presentedViewController;
    if (alertController) {
        UITextField* firstField = alertController.textFields.firstObject;
        UIAlertAction* okAction = alertController.actions.lastObject;
        okAction.enabled = firstField.text.length > 0;
    }
}

- (void)actionPreferences:(id)sender {
    PreferencesView* preferencesView = [[PreferencesView alloc] initWithFrame:CGRectMake(0, 0, 240, 280) delegate:self];
    _popup = [KLCPopup popupWithContentView:preferencesView showType:KLCPopupShowTypeBounceInFromTop dismissType:KLCPopupDismissTypeShrinkOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    [_popup show];
}

#pragma mark - FavouriteListener
- (void)favouriteChanged:(id<Favourite>)favourite {
    [_tableView reloadData];
    _profileImageView.image = _user.profileImage;
    _coverImageView.image = _user.coverImage;
}

#pragma mark - PreferencesViewDelegate
- (void)openMail {
    if ([MFMailComposeViewController canSendMail]) {
        [_popup dismissPresentingPopup];
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        [controller setToRecipients:@[@"info@d-32.com"]];
        [controller setSubject:@"GeoTappy"];
        controller.mailComposeDelegate = self;
        if (controller) [self presentViewController:controller animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    return [alertView textFieldAtIndex:0].text.length > 0;
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (_user.selectedFavourites.count == MAX_FAVS) {
            return @"Favourites (MAX 5)";
        } else {
            return @"Favourites";
        }
    } else if (section == 1) {
        return @"Other";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _user.selectedFavourites.count;
    } else if (section == 1) {
        return _user.unselectedFavourites.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<Favourite> fav;
    if (indexPath.section == 0) {
        fav = [_user.selectedFavourites objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        fav = [_user.unselectedFavourites objectAtIndex:indexPath.row];
    }
    CustomCell* cell = [[CustomCell alloc] initWithName:[fav displayName] favourite:fav];
    BOOL swipeEnabled = NO;
    if ([fav isKindOfClass:[Group class]]) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (((Group *)fav).friends.count > 0) {
            swipeEnabled = YES;
        }
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        swipeEnabled = YES;
    }
    if (swipeEnabled) {
        cell.rightButtons = @[[MGSwipeButton buttonWithTitle:@"Share" icon:[UIImage imageNamed:@"share"] backgroundColor:[UIColor colorWithRed:0.07 green:0.49 blue:0.97 alpha:1.00] callback:^BOOL(MGSwipeTableCell* cell) {
            
            if ([fav isKindOfClass:[Friend class]]) {
                Friend* friend = (Friend *)fav;
                [LocationPostmaster shareLocation:_locationManager.location toFriends:@[friend] completion:^(BOOL success) {
                    [self showStatus:success cell:cell];
                }];
            } else if ([fav isKindOfClass:[Group class]]) {
                [LocationPostmaster shareLocation:_locationManager.location toFriends:((Group *)fav).friends completion:^(BOOL success) {
                    [self showStatus:success cell:cell];
                }];
            }
            
            return NO;
        }]];
        cell.rightSwipeSettings.transition = MGSwipeTransitionStatic;
    }
    return cell;
}

- (void)showStatus:(BOOL)success cell:(MGSwipeTableCell *)cell {
    MGSwipeButton* button = [cell.rightButtons objectAtIndex:0];
    if (success) {
        button.backgroundColor = [UIColor colorWithRed:0.47 green:0.80 blue:0.12 alpha:1.00];
    } else {
        button.backgroundColor = [UIColor colorWithRed:0.64 green:0.00 blue:0.00 alpha:1.00];
    }
    [self performSelector:@selector(hideButtonForCell:) withObject:cell afterDelay:0.3];
}

- (void)hideButtonForCell:(MGSwipeTableCell *)cell {
    [cell hideSwipeAnimated:YES];
    MGSwipeButton* button = [cell.rightButtons objectAtIndex:0];
    [self performSelector:@selector(resetColor:) withObject:button afterDelay:0.5];
}

- (void)resetColor:(MGSwipeButton *)button {
    button.backgroundColor = [UIColor colorWithRed:0.07 green:0.49 blue:0.97 alpha:1.00];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return YES;
    } else {
        if (_user.selectedFavourites.count < MAX_FAVS) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.editing) {
        return UITableViewCellEditingStyleNone;
    }
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleDelete;
    } else {
        if (_user.selectedFavourites.count < MAX_FAVS) {
            return UITableViewCellEditingStyleInsert;
        } else {
            return UITableViewCellEditingStyleNone;
        }
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    id obj;
    if (sourceIndexPath.section == 0) {
        obj = [_user.selectedFavourites objectAtIndex:sourceIndexPath.row];
        [_user.selectedFavourites removeObjectAtIndex:sourceIndexPath.row];
    } else if (sourceIndexPath.section == 1) {
        obj = [_user.unselectedFavourites objectAtIndex:sourceIndexPath.row];
        [_user.unselectedFavourites removeObjectAtIndex:sourceIndexPath.row];
    }
    if (destinationIndexPath.section == 0) {
        [_user.selectedFavourites insertObject:obj atIndex:destinationIndexPath.row];
    } else if (destinationIndexPath.section == 1) {
        [_user.unselectedFavourites insertObject:obj atIndex:destinationIndexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<Favourite> fav;
    if (indexPath.section == 0) {
        fav = [_user.selectedFavourites objectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        fav = [_user.unselectedFavourites objectAtIndex:indexPath.row];
    }
    if ([fav isKindOfClass:[Group class]]) {
        GroupEditViewController* vc = [[GroupEditViewController alloc] initWithGroup:(Group *)fav user:_user];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)tableView:(UITableView *)tableView willBeginDraggingCellAtIndexPath:(NSIndexPath *)indexPath placeholderImageView:(UIImageView *)placeHolderImageView {
    placeHolderImageView.layer.shadowOpacity = 0.1;
    placeHolderImageView.layer.shadowRadius = 0.5;
    placeHolderImageView.layer.shadowOffset = CGSizeMake(1, 1);
}

- (void)tableView:(DragAndDropTableView *)tableView didEndDraggingCellAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)toIndexPath placeHolderView:(UIImageView *)placeholderImageView {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_user save];
    });
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
