# frozen_string_literal: true

module Canary
  module Mutations
    class WorkRecordUpdate < Canary::Mutations::Base
      argument :work_record_id, ID, required: true
      argument :body, String, required: false,
        description: "作品への感想"
      WorkRecord::STATES.each do |state|
        argument state.to_s.camelcase(:lower).to_sym, Canary::Types::Enums::RatingState, required: true,
          description: "作品への評価"
      end
      argument :share_twitter, Boolean, required: false,
        description: "作品への記録をTwitterでシェアするかどうか"
      argument :share_facebook, Boolean, required: false,
        description: "作品への記録をFacebookでシェアするかどうか"

      field :work_record, Canary::Types::Objects::WorkRecordType, null: true

      def resolve(
        work_record_id:,
        body: nil,
        rating_overall_state: nil,
        rating_animation_state: nil,
        rating_music_state: nil,
        rating_story_state: nil,
        rating_character_state: nil,
        share_twitter: nil,
        share_facebook: nil
      )
        raise Annict::Errors::InvalidAPITokenScopeError unless context[:writable]

        work_record = context[:viewer].work_records.published.find_by_graphql_id(work_record_id)

        work_record.body = body
        WorkRecord::STATES.each do |state|
          work_record.send("#{state}=".to_sym, send(state.to_s.camelcase(:lower).to_sym)&.downcase)
        end
        work_record.modified_at = Time.zone.now
        work_record.oauth_application = context[:application]
        work_record.detect_locale!(:body)

        context[:viewer].setting.attributes = {
          share_review_to_twitter: share_twitter == true,
          share_review_to_facebook: share_facebook == true
        }

        work_record.save!
        context[:viewer].setting.save!
        work_record.share_to_sns

        {
          work_record: work_record
        }
      end
    end
  end
end
