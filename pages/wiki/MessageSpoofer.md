---
title: 'Wiki: MessageSpoofer'
author: ron
layout: wiki
permalink: "/wiki/MessageSpoofer"
date: '2024-08-04T15:51:38-04:00'
redirect_from:
- "/wiki/index.php/MessageSpoofer"
---

## MessageSpoofer

-   Name: Message Spoofer
-   OS: Windows
-   Language: Visual Basic 6
-   Path: <http://svn.skullsecurity.org:81/ron/old/MessageSpoofer>
-   Created: Old
-   State: Complete (but out of date)

As far as I know, this program was the first of its kind. It allowed the user to spoof interesting messages (including animations) in Starcraft games by searching for a keyword in memory. It was pretty slick and worked well, and many people cloned the functionality.

Blizzard has, since then, removed this ability from their games. Oh well. :)

For old times sake, here are the automated messages that were included:

    ...
        Select Case strMessage
        Case "/normal"
            bCenter = False
            bCenterBottom = False
            bRight = False
            optColor(Asc(bwNOCOLOR)).Value = True
            txtUsername.Text = ""
        Case "/center"
            optCenter.Value = True
            strMessage = bwGREEN & "Center has been set." & AddLineFeeds
        Case "/bcenter"
            optBCenter.Value = True
            strMessage = bwGREEN & "BottomCenter has been set." & AddLineFeeds
        Case "/right"
            optRight.Value = True
            strMessage = bwGREEN & "Right has been set." & AddLineFeeds
        Case "/noalign"
            optLeft.Value = True
            strMessage = bwGREEN & "Left has been set." & AddLineFeeds
        Case "/left"
            optLeft.Value = True
            strMessage = bwGREEN & "Left has been set." & AddLineFeeds
        Case "/yellow"
            optColor(Asc(bwYELLOW)).Value = 1
            strMessage = bwYELLOW & "Yellow has been set." & AddLineFeeds
        Case "/white"
            optColor(Asc(bwWHITE)).Value = 1
            strMessage = bwWHITE & "White has been set." & AddLineFeeds
        Case "/grey"
            optColor(Asc(bwGREY)).Value = 1
            strMessage = bwGREY & "Grey has been set." & AddLineFeeds
        Case "/red"
            optColor(Asc(bwRED)).Value = 1
            strMessage = bwRED & "Red has been set." & AddLineFeeds
        Case "/green"
            optColor(Asc(bwGREEN)).Value = 1
            strMessage = bwGREEN & "Green has been set." & AddLineFeeds
        Case "/nocolor"
            optColor(Asc(bwNOCOLOR)).Value = 1
            strMessage = bwNOCOLOR & "Color has been removed." & AddLineFeeds
        Case "/colors"
            If chkReplaceColors.Value = 1 Then
                chkReplaceColors.Value = 0
                strMessage = bwRED & "Replace Colors Disabled" & AddLineFeeds
            Else
                chkReplaceColors.Value = 1
                strMessage = bwGREEN & "Replace Colors Enabled" & AddLineFeeds
            End If
        Case "/banned"
            If chkBanned.Value = 1 Then
                chkBanned.Value = 0
                strMessage = bwRED & "Banned Characters Disabled" & AddLineFeeds
            Else
                chkBanned.Value = 1
                strMessage = bwGREEN & "Banned Colors Enabled" & AddLineFeeds
            End If
        Case "/team"
            If chkTeam.Value = 1 Then
                chkTeam.Value = 0
                strMessage = bwRED & "Force Team Disabled" & AddLineFeeds
            Else
                chkTeam.Value = 1
                strMessage = bwGREEN & "Force Team Enabled" & AddLineFeeds
            End If
        End Select

        If Left(strMessage, Len("/name")) = "/name" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)
            strMessage = bwYELLOW & "Name is now " & strMessageArray(1) & AddLineFeeds & Chr(0)
            txtUsername.Text = strMessageArray(1)
        ElseIf strMessage = "/noname" Then
            txtUsername.Text = ""
            strMessage = bwRED & "Name has been removed." & AddLineFeeds
        End If

        If Left(strMessage, Len("/slowtext")) = "/slowtext" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)
            strMessage = "Hold [enter] to continue" & AddLineFeeds
            iPosition = 12
            strSlowText = AddLineFeeds & strMessageArray(1)
            tmrSlowText.Enabled = True
            bMarquee = False
        End If


        If Left(strMessage, Len("/mspeed")) = "/mspeed" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)
            If Val(strMessageArray(1)) <= 20 And Val(strMessageArray(1)) >= 1 Then
                strMessage = "Marquee Speed Set" & AddLineFeeds
                iMarqueeSpeed = Val(strMessageArray(1))
            Else
                strMessage = "Speed must be from 1-20" & AddLineFeeds
            End If
        End If

        If Left(strMessage, Len("/marquee")) = "/marquee" And Right(strMessage, 1) = "/" Then
            Dim strSpaces As String

            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)
            strMessage = "Hold [enter] to continue" & AddLineFeeds
            iPosition = 12
            tmrSlowText.Enabled = True
            bMarquee = True
            bMarqueeLeft = False

            iOffset = (15 / Len(strMessageArray(1))) - 1
            If iOffset < 1 Then
                'for long messages
                iOffset = Int(-(1 / iOffset) * 4)
            Else
                'for short messages
                iOffset = Int(iOffset / 2)
            End If

            'as much as I hate doing it, I have to pad this with spaces
            For iIndex = Len(AddLineFeeds) + Len(strMessageArray(1)) To 78
                strSpaces = " " & strSpaces
            Next

            strSlowText = AddLineFeeds & bwRIGHT & strMessageArray(1) & strSpaces
            strMarquee = strSpaces & strMessageArray(1)
        End If

        If strMessage = "/smile" Then
            strAnimation(1) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "0  0" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " |" & bwCRLF & _
                              Chr(3) & "\_____/"

            strAnimation(2) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "^  ^" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " |" & bwCRLF & _
                              Chr(3) & "\_____/"

            strAnimation(3) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "0  0" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " |" & bwCRLF & _
                              Chr(3) & "\_____/"

            strAnimation(4) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "^  ^" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " |" & bwCRLF & _
                              Chr(3) & "\_____/"

            strAnimation(5) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "0  0" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " | -- kekeke" & bwCRLF & _
                              Chr(3) & "\_____/"

            strAnimation(6) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              Chr(3) & " _____" & bwCRLF & _
                              Chr(3) & "/ " & Chr(7) & "^  ^" & Chr(1) & " \" & bwCRLF & _
                              Chr(3) & "|   v    |" & bwCRLF & _
                              Chr(3) & "| " & Chr(6) & "\___/" & Chr(1) & " | -- kekeke" & bwCRLF & _
                              Chr(3) & "\_____/"


            iFrame = 0
            tmrAnimation.Enabled = True
            strMessage = "Press [enter] to continue." & AddLineFeeds
        End If
        'Moo!
        If strMessage = "/cow" Then

            strAnimation(1) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              " //--------\\" & bwCRLF & _
                              "^^       ^^"
            strAnimation(2) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              "  | |-----| |" & bwCRLF & _
                              "  ^^    ^^"

            strAnimation(3) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              " //--------\\" & bwCRLF & _
                              "^^       ^^"
            strAnimation(4) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              "  | |-----| |" & bwCRLF & _
                              "  ^^    ^^"

            strAnimation(5) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              " //--------\\" & bwCRLF & _
                              "^^       ^^"
            strAnimation(6) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              "  | |-----| |" & bwCRLF & _
                              "  ^^    ^^"
            strAnimation(7) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              " //--------\\" & bwCRLF & _
                              "^^       ^^"
            strAnimation(8) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*      (__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              "  | |-----| |" & bwCRLF & _
                              "  ^^    ^^"
             strAnimation(8) = bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              bwCRLF & _
                              "*" & Chr(4) & "'Moo!'" & Chr(1) & "(__)" & bwCRLF & _
                              " \     (oo)" & bwCRLF & _
                              "  \-------\/" & bwCRLF & _
                              "  | |-----| |" & bwCRLF & _
                              "  ^^    ^^"

            iFrame = 0
            tmrAnimation.Enabled = True
            strMessage = "Press [enter] to continue." & AddLineFeeds
        End If

        '"Nuclear launch detected"
        If strMessage = "/nuke" Then
            strMessage = AddLineFeeds
            strMessage = strMessage & bwWHITE & bwCENTER & "Nuclear launch detected."
        End If

        'Cheat enabled
        If strMessage = "/cheat" Then
            strMessage = AddLineFeeds
            strMessage = strMessage & bwWHITE & bwCENTER & "Cheat enabled"
        End If

        'You have been backstabbed!
        If strMessage = "/bs" Then
            strMessage = AddLineFeeds
            strMessage = strMessage & bwRED & bwCENTER & "You have been backstabbed!" & bwCRLF & _
                                      bwWHITE & bwCENTER & "http://www.d2backstab.com"
        End If

        '$user has left the game
        If Left(strMessage, Len("/leave")) = "/leave" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)

            strMessage = AddLineFeeds
            strMessage = strMessage & bwYELLOW & strMessageArray(1) & " has left the game."
        End If

        '$user was eliminated
        If Left(strMessage, Len("/kill")) = "/kill" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)

            strMessage = AddLineFeeds
            strMessage = strMessage & bwYELLOW & strMessageArray(1) & " was eliminated."
        End If

        If Left(strMessage, Len("/drop")) = "/drop" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)

            strMessage = AddLineFeeds
            strMessage = strMessage & bwYELLOW & strMessageArray(1) & " was dropped from the game."
        End If

        If Left(strMessage, Len("/join")) = "/join" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 2)

            strMessage = AddLineFeeds
            strMessage = strMessage & bwYELLOW & strMessageArray(1) & " has joined the game."
        End If

        If Left(strMessage, Len("/latency")) = "/latency" And Right(strMessage, 1) = "/" Then
            strMessage = Left(strMessage, Len(strMessage) - 1)
            strMessageArray = Split(strMessage, " ", 3)

            strMessage = AddLineFeeds
            strMessage = strMessage & bwYELLOW & "Player " & strMessageArray(1) & " set network for " & strMessageArray(2) & " latency"
        End If
    ...

    svn co http://svn.skullsecurity.org:81/ron/old/MessageSpoofer
