import 'package:fish_redux/fish_redux.dart';
import 'package:gitbbs/network/GitHttpRequest.dart';
import 'package:gitbbs/network/github/GithubHttpRequest.dart';
import 'package:gitbbs/ui/editcomment/action.dart';
import 'package:gitbbs/ui/editcomment/state.dart';
import 'package:gitbbs/ui/widget/loading.dart';
import 'package:markdown_editor/markdown_editor.dart';
import 'package:flutter/material.dart';
import 'package:gitbbs/model/entry/comment_edit_data.dart';

Effect<EditCommentState> buildEffect() {
  return combineEffects(<Object, Effect<EditCommentState>>{
    Lifecycle.initState: _init,
    EditCommentAction.togglePageType: _togglePageType,
    EditCommentAction.checkSubmitComment: _checkSubmitComment,
    EditCommentAction.submitComment: _submitComment
  });
}

void _init(Action action, Context<EditCommentState> ctx) async {}

void _togglePageType(Action action, Context<EditCommentState> ctx) async {
  var pageType = ctx.state.getCurrentPage();
  if (pageType == PageType.preview) {
    pageType = PageType.editor;
  } else {
    pageType = PageType.preview;
  }
  ctx.state.mdKey.currentState.setCurrentPage(pageType);
  ctx.dispatch(EditCommentActionCreator.pageTypeChangedAction());
}

void _submitComment(Action action, Context<EditCommentState> ctx) async {
  String body = ctx.state.getBody();
  GitHttpRequest request = GithubHttpRequest.getInstance();
  var success = false;
  var dialog = LoadingDialog.show(ctx.context);
  if (ctx.state.type == Type.modify) {
    String commentId = ctx.state.comment.getId();
    success = await request.modifyComment(commentId, body);
  } else {
    String issueId = ctx.state.issue.getId();
    success = await request.addComment(issueId, body);
  }
  dialog.dismiss();
  if (success == true) {
    ctx.state.scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text('提交成功')));
    Navigator.of(ctx.context).pop();
    return;
  }
  ctx.state.scaffoldKey.currentState
      .showSnackBar(SnackBar(content: Text('提交失败')));
}

void _checkSubmitComment(Action action, Context<EditCommentState> ctx) {
  if (ctx.state.isBodyEmpty()) {
    ctx.state.scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text('内容不得为空')));
    return;
  }
  showDialog(
      context: ctx.context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('提示'),
          content: Text('是否提交评论？'),
          actions: <Widget>[
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('取消')),
            FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ctx.dispatch(EditCommentActionCreator.submitCommentAction());
                },
                child: Text('确定')),
          ],
        );
      });
}
