module War {

    //国战状态改变
    function rpc_ChangeWarState(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignState.decode(payload);
        WarMgr.inst.updateState(reply);
    }

    // 城市状态改变
    function rpc_ChangeCityState(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateCityStateArg.decode(payload);
        let cityId = reply.CityID;
        let city = CityMgr.inst.getCity(cityId);
        city.changeStatus(reply.State, -1, reply.OccupyCountryID);
    }

    // 自己的队伍状态改变
    function rpc_ChangeMyTeamState(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateMyTeamStateArg.decode(payload);
        let state = reply.State;
        let myTeam = WarTeamMgr.inst.myTeam;
        if (myTeam) {
            myTeam.changeStatus(state, -1, reply.Arg);
        }
    }

    // 玩家状态改变
    function rpc_ChangePlayerState(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignPlayerState.decode(payload);
        MyWarPlayer.inst.changeStatus(reply.State, -1, reply.Arg);
    }

    // 所有其他队伍的状态改变
    function rpc_ChangeOtherTeamsState(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignTeams.decode(payload);
        reply.Teams.forEach(teamData => {

            console.log(`rpc_ChangeOtherTeamsState team: ${teamData.ID.toString()}, state: ${teamData.State.toString()}`);
            let teamId = teamData.ID;
            if (!WarTeamMgr.inst.myTeam || WarTeamMgr.inst.myTeam.teamID != teamId) {
                console.log("rpc_ChangeOtherTeamsState handle team ", teamId);
                let team = WarTeamMgr.inst.getOtherTeam(teamId);
                if (team) {
                    team.changeStatus(teamData.State);
                    team.amount = teamData.TeamAmount;
                } else if (teamData.State != <number>TeamStatusName.ST_DISAPPEAR) {
                    team = new WarTeam(<pb.TeamData>teamData);
                    WarTeamMgr.inst.addOtherTeam(team);
                    team.amount = teamData.TeamAmount;
                }

                team = WarTeamMgr.inst.getOtherTeam(teamId);
                if (!team || team.destroyed || !WarTeamMgr.inst.myTeam) {
                    return;
                } 

                let othRoad = team.road;
                let myRoad = WarTeamMgr.inst.myTeam.road;
                if (!othRoad || !myRoad || othRoad.id != myRoad.id || othRoad.toCityId != myRoad.toCityId) {
                    return;
                }

                WarTeamMgr.inst.myTeam.amount = 0;
            } else {

                WarTeamMgr.inst.myTeam.amount = teamData.TeamAmount;
            }
        });
    }



    function rpc_CountryCreated(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let countryData = pb.CountryCreatedArg.decode(payload);
        WarMgr.inst.countryCreated(countryData);
    }
    //势力被消灭
    function rpc_CountryDestoryed(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let countryData = pb.CountryDestoryed.decode(payload);
        WarMgr.inst.countryDestoryed(countryData);
    }
    // function rpc_CountryBeOccupy(_:Net.RemoteProxy, payload: Uint8Array) {
    //     let occupyData = pb.CityBeOccupyArg.decode(payload);
    //     WarMgr.inst.occupyCity(occupyData.CityID, occupyData.CountryID);
    // }
    function rpc_UpdateForage(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let forage = pb.UpdateForageArg.decode(payload);
       MyWarPlayer.inst.forage = forage.ForageAmount;
    }
    //显示红点
    function rpc_ShowNotifyRedDot(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignNotifyRedDotArg.decode(payload);
        if (reply.Type == pb.CampaignNotifyRedDotArg.RedDotType.Misson) {
            Core.EventCenter.inst.dispatchEventWith(WarMgr.ShowMissionRedDot);
        } else if (reply.Type == pb.CampaignNotifyRedDotArg.RedDotType.Notice) {
            Core.EventCenter.inst.dispatchEventWith(WarMgr.ShowNotifyRedDot, false, true);
        }
    }
    //城防改变
    function rpc_UpdateCityDefense(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.SyncCityDefenseArg.decode(payload);
        reply.CityDefenses.forEach(_data => {
            let city = CityMgr.inst.getCity(_data.CityID);
            if (city) {
                city.defence = _data.Defense;
            }
        })
    }
    //自己的职位变更
    async function rpc_UpdateMyJob(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignUpdateJobArg.decode(payload);
        await MyWarPlayer.inst.employee.setCityJob(<number>reply.CityJob);
        await MyWarPlayer.inst.employee.setCountryJob(<number>reply.CountryJob);
        Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshCityInfo);
        Core.EventCenter.inst.dispatchEventWith(WarMgr.RefreshAppoint);
    }
    //自己的队伍可以攻击
    function rpc_CanAttack(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
    }
    //成为俘虏
    function rpc_BeCaptive(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
    }
    //修改我所属城市
    function rpc_UpdateMyCity(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateMyCityArg.decode(payload);
        MyWarPlayer.inst.cityID = reply.CityID;
        MyWarPlayer.inst.locationCityID = reply.LocationCityID;
    }
    //修改我所属国家
    function rpc_UpdateMyCountry(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateMyCountryArg.decode(payload);
        MyWarPlayer.inst.countryID = reply.CountryID;
        MyWarPlayer.inst.lastCountryID = reply.LastCountryID;
    }
    //更新我可攻击的城池
    // function rpc_UpdateCanAttackCity(_:Net.RemoteProxy, payload: Uint8Array) {
        
    // }
    //国战结束
    function rpc_WarEnd(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
    }
    //更新国家名
    function rpc_UpdateCountryName(_:Net.RemoteProxy, payload: Uint8Array) {  
        if (!WarMgr.initialized) {
            return;
        }      
        let reply = pb.UpdateCountryNameArg.decode(payload);
        WarMgr.inst.updateCountryName(reply.CountryID, reply.Name);
    }
    //更新国家旗
    function rpc_UpdateCountryFlag(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateCountryFlagArg.decode(payload);
        WarMgr.inst.updateCountryFlag(reply.CountryID, reply.Flag);
    }
    function rpc_UpdateContribution(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateContributionArg.decode(payload);
        MyWarPlayer.inst.contribution = reply.Contribution;
        MyWarPlayer.inst.contributionMax = reply.MaxContribution;
    }
    function rpc_UpdateCityPlayerNum(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.SyncCityPlayerAmount.decode(payload);
        CityMgr.inst.getCity(reply.CityID).playerNum = reply.Amount;
    }
    function rpc_UpdateCityDefPlayerNum(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CitysDefPlayerAmount.decode(payload);
        CityMgr.inst.setAllCityDefPlayers(reply);
    }
    //更新支援的卡组
    function rpc_UpdateSupportCards(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.CampaignSupportCard.decode(payload);
        MyWarPlayer.inst.supportCards = reply.CardIDs;
    }
    //更新城市势力rpc_UpdateCitysCountry
    function rpc_UpdateCitysCountry(_:Net.RemoteProxy, payload: Uint8Array) {
        if (!WarMgr.initialized) {
            return;
        }
        let reply = pb.UpdateCityCountryArg.decode(payload);
        let city = CityMgr.inst.getCity(reply.CityID);
        if (city.countryID != 0) {
            let oldCountry = CountryMgr.inst.getCountry(city.countryID);
            oldCountry.delCity(city);
        }
        let newCountry = CountryMgr.inst.getCountry(reply.CountryID);
        if (newCountry) {
            newCountry.addCity(city);
        }
        city.countryID = reply.CountryID;
    }
  
    export function initRpc() {
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CAMPAIGN_STATE, rpc_ChangeWarState);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CITY_STATE, rpc_ChangeCityState);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MY_TEAM_STATE, rpc_ChangeMyTeamState);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CAMPAIGN_PLAYER_STATE, rpc_ChangePlayerState);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CAMPAIGN_TEAMS, rpc_ChangeOtherTeamsState);


        Net.registerRpcHandler(pb.MessageID.S2C_COUNTRY_CREATED, rpc_CountryCreated);
        // Net.registerRpcHandler(pb.MessageID.S2C_CITY_BE_OCCUPY, rpc_CountryBeOccupy);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_FORAGE, rpc_UpdateForage);
        Net.registerRpcHandler(pb.MessageID.S2C_CAMPAIGN_NOTIFY_RED_DOT, rpc_ShowNotifyRedDot);
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_CITY_DEFENSE, rpc_UpdateCityDefense);
        // Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CITY_BE_ATTACK_STATE, rpc_AttackMyLocationCity);
        Net.registerRpcHandler(pb.MessageID.S2C_CAMPAIGN_UPDATE_JOB, rpc_UpdateMyJob);
        Net.registerRpcHandler(pb.MessageID.S2C_MY_TEAM_CAN_ATTACK_CITY, rpc_CanAttack);
        Net.registerRpcHandler(pb.MessageID.S2C_TO_BE_CAPTIVE, rpc_BeCaptive);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MY_CITY, rpc_UpdateMyCity);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_MY_COUNTRY, rpc_UpdateMyCountry);
        Net.registerRpcHandler(pb.MessageID.S2C_COUNTRY_WAR_END, rpc_WarEnd);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_COUNTRY_NAME, rpc_UpdateCountryName);
        Net.registerRpcHandler(pb.MessageID.S2C_COUNTRY_DESTORYED, rpc_CountryDestoryed);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_COUNTRY_FLAG, rpc_UpdateCountryFlag);
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_CITY_PLYAER_AMOUNT, rpc_UpdateCityPlayerNum);
        Net.registerRpcHandler(pb.MessageID.S2C_SYNC_DEF_CITY_PLAYER_AMOUNT, rpc_UpdateCityDefPlayerNum);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CAMPAIGN_SUPPORT_CARDS, rpc_UpdateSupportCards);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CONTRIBUTION, rpc_UpdateContribution);
        Net.registerRpcHandler(pb.MessageID.S2C_UPDATE_CITY_COUNTRY, rpc_UpdateCitysCountry);
    }
}
