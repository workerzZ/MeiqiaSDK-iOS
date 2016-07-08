//
//  MQAdviseFormSubmitViewController.m
//  Meiqia-SDK-Demo
//
//  Created by ian luo on 16/6/29.
//  Copyright © 2016年 Meiqia. All rights reserved.
//

#import "MQPreChatSubmitViewController.h"
#import "MQPreChatFormViewModel.h"
#import "UIView+MQLayout.h"
#import "NSArray+MQFunctional.h"
#import "MQPreChatCells.h"
#import "MQToast.h"

#pragma mark -
#pragma mark -

@interface MQPreChatSubmitViewController ()

@property (nonatomic, strong) MQPreChatFormViewModel *viewModel;

@end

@implementation MQPreChatSubmitViewController

- (instancetype)init {
    if (self = [super initWithStyle:(UITableViewStyleGrouped)]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"请填写以下问题";
    
    self.viewModel = [MQPreChatFormViewModel new];
    self.viewModel.formData = self.formData;

    self.tableView.allowsMultipleSelection = YES;
    
    [self.tableView registerClass:[MQPreChatMultiLineTextCell class] forCellReuseIdentifier:NSStringFromClass([MQPreChatMultiLineTextCell class])];
    [self.tableView registerClass:[MQPrechatSingleLineTextCell class] forCellReuseIdentifier:NSStringFromClass([MQPrechatSingleLineTextCell class])];
    [self.tableView registerClass:[MQPreChatSelectionCell class] forCellReuseIdentifier:NSStringFromClass([MQPreChatSelectionCell class])];
    [self.tableView registerClass:[MQPreChatCaptchaCell class] forCellReuseIdentifier:NSStringFromClass([MQPreChatCaptchaCell class])];
    [self.tableView registerClass:[MQPreChatSectionHeaderView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([MQPreChatSectionHeaderView class])];
    
    UIBarButtonItem *submit = [[UIBarButtonItem alloc] initWithTitle:@"提交" style:(UIBarButtonItemStylePlain) target:self action:@selector(submitAction)];
    self.navigationItem.rightBarButtonItem = submit;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    MQPreChatSectionHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([MQPreChatSectionHeaderView class])];
    
    header.viewSize = CGSizeMake(tableView.viewWidth, 40);
    header.viewOrigin = CGPointZero;
    header.formItem = self.viewModel.formData.form.formItems[section];
    
    return header;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MQPreChatFormItem *formItem = (MQPreChatFormItem *)self.viewModel.formData.form.formItems[indexPath.section];
    
    UITableViewCell *cell;
    __weak typeof(self) wself = self;
    switch (formItem.type) {
        case MQPreChatFormItemInputTypeSingleLineText:
        {
            MQPrechatSingleLineTextCell *scell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MQPrechatSingleLineTextCell.class) forIndexPath:indexPath];
            
            //记录用户输入
            [scell setValueChangedAction:^(NSString *newString) {
                __strong typeof (wself) sself = wself;
                [sself.viewModel setValue:newString forFieldIndex:indexPath.section];
            }];
            scell.textField.text = [self.viewModel valueForFieldIndex:indexPath.section];
            cell = scell;
            break;
        }
        case MQPreCHatFormItemInputTypeMultipleLineText:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MQPreChatMultiLineTextCell.class) forIndexPath:indexPath];
            break;
        case MQPreChatFormItemInputTypeSingleSelection:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MQPreChatSelectionCell.class) forIndexPath:indexPath];
            cell.textLabel.text = formItem.choices[indexPath.row];
            [cell setSelected:([@(indexPath.row) isEqual:[self.viewModel valueForFieldIndex:indexPath.section]]) animated:NO];
            break;
        case MQPreChatFormItemInputTypeMultipleSelection:
            cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MQPreChatSelectionCell.class) forIndexPath:indexPath];
            cell.textLabel.text = formItem.choices[indexPath.row];
            
            if ([[self.viewModel valueForFieldIndex:indexPath.section] respondsToSelector:@selector(containsObject:)]) {
                [cell setSelected:[[self.viewModel valueForFieldIndex:indexPath.section] containsObject:@(indexPath.row)] animated:NO];
            }
            break;
        case MQPreChatFormItemInputTypeCaptcha:{
            MQPreChatCaptchaCell *ccell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MQPreChatCaptchaCell.class) forIndexPath:indexPath];
            ccell.textField.text = [self.viewModel valueForFieldIndex:indexPath.section];
            //刷新验证码
            ccell.loadCaptchaAction = ^(UIButton *button){
                __strong typeof (wself) sself = wself;
                [sself.viewModel requestCaptchaComplete:^(UIImage *image) {
                    [button setImage:image forState:(UIControlStateNormal)];
                }];
            };
            
            //记录用户输入
            [ccell setValueChangedAction:^(NSString *newString) {
                __strong typeof (wself) sself = wself;
                [sself.viewModel setValue:newString forFieldIndex:indexPath.section];
            }];
            
            //cell 第一次出现后自动加载图片
            if ([self.viewModel.captchaToken length] == 0) {
                [self.viewModel requestCaptchaComplete:^(UIImage *image) {
                    [ccell.refreshCapchaButton setImage:image forState:UIControlStateNormal];
                }];
            }
            
            cell = ccell;
        }
            break;
    }
    
    
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.tableView endEditing:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.viewModel.formData.form.formItems[section] choices] count] ?: 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView endEditing:YES];
    
    MQPreChatFormItem *formItem = (MQPreChatFormItem *)self.viewModel.formData.form.formItems[indexPath.section];
    
    if (formItem.type == MQPreChatFormItemInputTypeSingleSelection) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:(UITableViewScrollPositionNone)];
        [self.viewModel setValue:@(indexPath.row) forFieldIndex:indexPath.section];
    }else if (formItem.type == MQPreChatFormItemInputTypeMultipleSelection) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:(UITableViewScrollPositionNone)];
        
        NSArray *selectedRowsInCurrentSection = [[[tableView indexPathsForSelectedRows] filter:^BOOL(NSIndexPath *i) {
            return i.section == indexPath.section;
        }] map:^id(NSIndexPath *i) {
            return @(i.row);
        }];
        [self.viewModel setValue:selectedRowsInCurrentSection forFieldIndex:indexPath.section];
    }
    
    if ( formItem.type != MQPreChatFormItemInputTypeMultipleSelection) {
        for (int i = 0; i < [[formItem choices] count]; i++) {
            if (i != indexPath.row) {
                [tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:NO];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView endEditing:YES];
    
    NSArray *selectedRowsInCurrentSection = [[[tableView indexPathsForSelectedRows] filter:^BOOL(NSIndexPath *i) {
        return i.section == indexPath.section;
    }] map:^id(NSIndexPath *i) {
        return @(i.row);
    }];
    [self.viewModel setValue:selectedRowsInCurrentSection.count > 0 ? selectedRowsInCurrentSection : nil forFieldIndex:indexPath.section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.formData.form.formItems.count;
}

- (void)submitAction {
    NSArray *unsatisfiedSections = [self.viewModel submitForm];
    
    if (unsatisfiedSections.count > 0) {
        for (int i = 0; i < self.viewModel.formData.form.formItems.count; i ++) {
            MQPreChatSectionHeaderView *header = (MQPreChatSectionHeaderView *)[self.tableView headerViewForSection:i];
            [header setStatus:![unsatisfiedSections containsObject:@(i)]];
        }
        
        [MQToast showToast:@"xxxxx" duration:2 window:[[UIApplication sharedApplication].windows lastObject]];
        
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            [self setupConfigInfo];
            if (self.completeBlock) {
                self.completeBlock();
            }
        }];
    }
}

//
- (void)setupConfigInfo {
    NSString *target = self.selectedMenuItem.target;
    NSString *targetType = self.selectedMenuItem.targetKind;
    
    if ([targetType isEqualToString:@"agent"]) {
        self.config.scheduledAgentId = target;
    } else if ([targetType isEqualToString:@"group"]) {
        self.config.scheduledGroupId = target;
    }
}


@end
