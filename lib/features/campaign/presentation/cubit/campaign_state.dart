import 'package:equatable/equatable.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';

abstract class CampaignState extends Equatable {
  const CampaignState();

  @override
  List<Object?> get props => [];
}

class CampaignInitial extends CampaignState {
  const CampaignInitial();
}

class CampaignLoading extends CampaignState {
  const CampaignLoading();
}

class CampaignLoaded extends CampaignState {
  const CampaignLoaded(this.campaigns);

  final List<Campaign> campaigns;

  @override
  List<Object?> get props => [campaigns];
}

class CampaignError extends CampaignState {
  const CampaignError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
